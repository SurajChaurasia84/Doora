import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/task.dart';
import '../../domain/task_validator.dart';
import '../providers/task_controller.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  static const routeName = '/task-form';

  const TaskFormScreen({super.key});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _status = TaskStatus.pending;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _submitting = false;
  Task? _editingTask;
  late final AnimationController _titleShakeController;
  late final AnimationController _descriptionShakeController;
  late final Animation<double> _titleShakeOffset;
  late final Animation<double> _descriptionShakeOffset;

  @override
  void initState() {
    super.initState();
    _titleShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _descriptionShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _titleShakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _titleShakeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _descriptionShakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _descriptionShakeController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Task && _editingTask == null) {
      _editingTask = arg;
      _titleController.text = arg.title;
      _descriptionController.text = arg.description;
      _status = arg.status;
      _dueDate = arg.dueDate;
    }
  }

  @override
  void dispose() {
    _titleShakeController.dispose();
    _descriptionShakeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (result != null) {
      setState(() => _dueDate = result);
    }
  }

  Future<void> _submit() async {
    final titleError = TaskValidator.validateTitle(_titleController.text);
    final descriptionError = TaskValidator.validateDescription(
      _descriptionController.text,
    );

    if (titleError != null || descriptionError != null) {
      _formKey.currentState!.validate();
      _runFieldShakes(
        shakeTitle: titleError != null,
        shakeDescription: descriptionError != null,
      );
      return;
    }
    setState(() => _submitting = true);

    final baseTask = Task(
      id: _editingTask?.id ?? 0,
      title: _toSentenceCaseBySentence(_titleController.text),
      description: _toSentenceCaseBySentence(_descriptionController.text),
      status: _status,
      dueDate: _dueDate,
    );

    final controller = ref.read(taskControllerProvider.notifier);
    final ok = _editingTask == null
        ? await controller.createTask(baseTask)
        : await controller.updateTask(baseTask);

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      final error = ref.read(taskControllerProvider).error ?? 'Failed to save';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _runFieldShakes({
    required bool shakeTitle,
    required bool shakeDescription,
  }) {
    if (shakeTitle && !_titleShakeController.isAnimating) {
      _titleShakeController.forward(from: 0);
    }
    if (shakeDescription && !_descriptionShakeController.isAnimating) {
      _descriptionShakeController.forward(from: 0);
    }
  }

  String _toSentenceCaseBySentence(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return cleaned;
    final buffer = StringBuffer();
    var capitalizeNext = true;

    for (final rune in cleaned.runes) {
      final char = String.fromCharCode(rune);
      final isLetter = RegExp(r'[A-Za-z]').hasMatch(char);

      if (isLetter) {
        if (capitalizeNext) {
          buffer.write(char.toUpperCase());
          capitalizeNext = false;
        } else {
          buffer.write(char.toLowerCase());
        }
      } else {
        buffer.write(char);
        if (char == '.' || char == '!' || char == '?') {
          capitalizeNext = true;
        }
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingTask != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Task' : 'Create Task')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _titleShakeOffset,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_titleShakeOffset.value, 0),
                      child: child,
                    ),
                    child: AppTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Plan sprint review',
                      textCapitalization: TextCapitalization.sentences,
                      validator: TaskValidator.validateTitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _descriptionShakeOffset,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_descriptionShakeOffset.value, 0),
                      child: child,
                    ),
                    child: AppTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Prepare action items and blockers.',
                      textCapitalization: TextCapitalization.sentences,
                      validator: TaskValidator.validateDescription,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: TaskStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due Date'),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM, yyyy').format(_dueDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: isEditing ? 'Update Task' : 'Create Task',
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
