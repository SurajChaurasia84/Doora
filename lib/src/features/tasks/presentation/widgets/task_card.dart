import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case TaskStatus.pending:
        return Theme.of(context).colorScheme.secondary;
      case TaskStatus.inProgress:
        return Theme.of(context).colorScheme.tertiary;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM, yyyy').format(task.dueDate);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    Icons.flag_circle_rounded,
                    size: 16,
                    color: _statusColor(context),
                  ),
                  label: Text(task.status.label),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(dateLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
