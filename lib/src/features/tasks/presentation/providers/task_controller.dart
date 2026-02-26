import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/task_api_service.dart';
import '../../data/task_cache_service.dart';
import '../../domain/task.dart';
import 'task_state.dart';

final taskApiServiceProvider = Provider<TaskApiService>((ref) {
  return TaskApiService(ref.read(tasksDioProvider));
});

final taskCacheServiceProvider = Provider<TaskCacheService>((_) {
  return TaskCacheService();
});

final taskControllerProvider = StateNotifierProvider<TaskController, TaskState>(
  (ref) {
    return TaskController(
      ref.read(taskApiServiceProvider),
      ref.read(taskCacheServiceProvider),
    );
  },
);

class TaskController extends StateNotifier<TaskState> {
  static const _pageSize = 15;
  final TaskApiService _api;
  final TaskCacheService _cache;

  int _remoteLoadedCount = 0;

  TaskController(this._api, this._cache) : super(const TaskState());

  Future<void> initialize() async {
    if (state.tasks.isNotEmpty || state.isLoading) return;
    final cached = await _cache.readTasks();
    if (cached.isNotEmpty) {
      state = state.copyWith(tasks: cached);
      _remoteLoadedCount = cached.where((t) => !t.isUserCreated).length;
    }
    await loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, hasMore: true, clearError: true);
    _remoteLoadedCount = 0;
    try {
      final tasks = await _api.fetchTasks(limit: _pageSize, skip: 0);
      final merged =
          _mergeWithLocalDetailsAndKeepUserCreated(tasks, state.tasks);
      state = state.copyWith(
        tasks: merged,
        isLoading: false,
        hasMore: tasks.length == _pageSize,
        clearError: true,
      );
      _remoteLoadedCount = tasks.length;
      await _cache.saveTasks(state.tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      _remoteLoadedCount = 0;
      final tasks = await _api.fetchTasks(limit: _pageSize, skip: 0);
      final merged =
          _mergeWithLocalDetailsAndKeepUserCreated(tasks, state.tasks);
      state = state.copyWith(
        tasks: merged,
        isRefreshing: false,
        hasMore: tasks.length == _pageSize,
      );
      _remoteLoadedCount = tasks.length;
      await _cache.saveTasks(state.tasks);
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final tasks = await _api.fetchTasks(
        limit: _pageSize,
        skip: _remoteLoadedCount,
      );
      final next = [
        ...state.tasks,
        ..._mergeWithLocalDetailsAndKeepUserCreated(tasks, state.tasks),
      ];
      final uniqueById = <int, Task>{for (final item in next) item.id: item};
      state = state.copyWith(
        tasks: uniqueById.values.toList(),
        isLoadingMore: false,
        hasMore: tasks.length == _pageSize,
      );
      _remoteLoadedCount += tasks.length;
      await _cache.saveTasks(state.tasks);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<bool> createTask(Task task) async {
    // Keep user-created tasks truly local and stable using unique negative IDs.
    // Mock APIs can return repeated IDs, which can collapse items during merges.
    final localCreated = task.copyWith(
      id: _nextLocalId(),
      isUserCreated: true,
    );
    state = state.copyWith(
      tasks: [localCreated, ...state.tasks],
      clearError: true,
    );
    await _cache.saveTasks(state.tasks);

    try {
      await _api.createTask(task);
      return true;
    } catch (e) {
      // Local persistence already succeeded; keep UX successful in offline/mock failures.
      return true;
    }
  }

  Future<bool> updateTask(Task task) async {
    final existing = state.tasks
        .where((t) => t.id == task.id)
        .cast<Task?>()
        .firstWhere((t) => t != null, orElse: () => null);
    if (existing?.isUserCreated == true) {
      final updatedLocal = task.copyWith(isUserCreated: true);
      state = state.copyWith(
        tasks: state.tasks
            .map((t) => t.id == task.id ? updatedLocal : t)
            .toList(),
        clearError: true,
      );
      await _cache.saveTasks(state.tasks);
      return true;
    }

    try {
      final updated = await _api.updateTask(task);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == task.id ? updated : t).toList(),
        clearError: true,
      );
      await _cache.saveTasks(state.tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    final existing = state.tasks
        .where((t) => t.id == id)
        .cast<Task?>()
        .firstWhere((t) => t != null, orElse: () => null);
    if (existing?.isUserCreated == true) {
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      await _cache.saveTasks(state.tasks);
      return true;
    }

    try {
      await _api.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      await _cache.saveTasks(state.tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  List<Task> _mergeWithLocalDetailsAndKeepUserCreated(
    List<Task> remote,
    List<Task> local,
  ) {
    final localById = {for (final item in local) item.id: item};
    final mergedRemote = remote.map((task) {
      final localTask = localById[task.id];
      if (localTask == null) return task;
      return task.copyWith(
        description: localTask.description,
        dueDate: localTask.dueDate,
        status: localTask.status,
      );
    }).toList();

    final remoteIds = mergedRemote.map((t) => t.id).toSet();
    final userCreatedOnly = local
        .where((t) => t.isUserCreated && !remoteIds.contains(t.id))
        .toList();

    return [...userCreatedOnly, ...mergedRemote];
  }

  int _nextLocalId() {
    if (state.tasks.isEmpty) return -1;
    final minId = state.tasks.map((t) => t.id).reduce((a, b) => a < b ? a : b);
    return minId <= 0 ? minId - 1 : -1;
  }
}
