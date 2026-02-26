import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task.dart';

class TaskCacheService {
  static const _tasksKey = 'cached_tasks';

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = tasks.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_tasksKey, encoded);
  }

  Future<List<Task>> readTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_tasksKey) ?? [];
    return encoded
        .map((e) => Task.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }
}
