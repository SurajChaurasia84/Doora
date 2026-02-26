import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/task.dart';

class TaskApiService {
  final Dio _dio;

  const TaskApiService(this._dio);

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    const maxAttempts = 2;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } on DioException catch (e) {
        if (attempt == maxAttempts) {
          throw AppException(
            e.response?.data is Map<String, dynamic>
                ? (e.response?.data['message']?.toString() ?? 'Request failed')
                : 'Network request failed',
          );
        }
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
      }
    }
    throw const AppException('Unexpected network error');
  }

  Future<List<Task>> fetchTasks({required int limit, required int skip}) async {
    return _withRetry(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/todos',
        queryParameters: {'limit': limit, 'skip': skip},
      );
      final todos = (response.data?['todos'] as List<dynamic>? ?? []);
      return todos
          .map((e) => Task.fromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<Task> createTask(Task task) async {
    return _withRetry(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/todos/add',
        data: {
          'todo': task.title,
          'completed': task.status.isDone,
          'userId': 1,
        },
      );
      final created =
          Task.fromApi(Map<String, dynamic>.from(response.data ?? {})).copyWith(
            description: task.description,
            dueDate: task.dueDate,
            status: task.status,
          );
      return created;
    });
  }

  Future<Task> updateTask(Task task) async {
    return _withRetry(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/todos/${task.id}',
        data: {'todo': task.title, 'completed': task.status.isDone},
      );
      final updated =
          Task.fromApi(Map<String, dynamic>.from(response.data ?? {})).copyWith(
            description: task.description,
            dueDate: task.dueDate,
            status: task.status,
          );
      return updated;
    });
  }

  Future<void> deleteTask(int id) async {
    await _withRetry(() async {
      await _dio.delete<void>('/todos/$id');
    });
  }
}
