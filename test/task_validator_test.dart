import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_pro/src/features/tasks/domain/task_validator.dart';

void main() {
  group('TaskValidator', () {
    test('validates title correctly', () {
      expect(TaskValidator.validateTitle(''), isNotNull);
      expect(TaskValidator.validateTitle('ab'), isNotNull);
      expect(TaskValidator.validateTitle('Valid title'), isNull);
    });

    test('validates description correctly', () {
      expect(TaskValidator.validateDescription(''), isNotNull);
      expect(TaskValidator.validateDescription('too short'), isNotNull);
      expect(
        TaskValidator.validateDescription('This is a valid description.'),
        isNull,
      );
    });
  });
}
