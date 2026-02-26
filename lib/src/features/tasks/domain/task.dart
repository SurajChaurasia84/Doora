enum TaskStatus { pending, inProgress, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  bool get isDone => this == TaskStatus.completed;

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return TaskStatus.completed;
      case 'inProgress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime dueDate;
  final bool isUserCreated;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.dueDate,
    this.isUserCreated = false,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    bool? isUserCreated,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  factory Task.fromApi(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final completed = json['completed'] == true;
    return Task(
      id: id,
      title: (json['todo'] ?? 'Untitled').toString(),
      description: 'Task #$id',
      status: completed ? TaskStatus.completed : TaskStatus.pending,
      dueDate: DateTime.now().add(Duration(days: (id % 7) + 1)),
      isUserCreated: false,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: (json['id'] as num).toInt(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      status: TaskStatusX.fromString(json['status'].toString()),
      dueDate: DateTime.parse(json['dueDate'].toString()),
      isUserCreated: json['isUserCreated'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'dueDate': dueDate.toIso8601String(),
        'isUserCreated': isUserCreated,
      };
}
