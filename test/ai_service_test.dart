import 'package:flutter_test/flutter_test.dart';
import 'package:life_saver/services/ai_service.dart';
import 'package:life_saver/models/task_model.dart';

void main() {
  group('AiService Priority Engine Tests', () {
    final aiService = AiService();

    test('Overdue tasks should receive maximum priority score', () {
      final deadline = DateTime.now().subtract(const Duration(hours: 1));
      final score = aiService.calculatePriorityScore(deadline, 60, 'High', 'High');
      expect(score, equals(100.0));
    });

    test('Urgent tasks with high complexity and energy should have higher score than distant simple tasks', () {
      final urgentDeadline = DateTime.now().add(const Duration(hours: 2));
      final distantDeadline = DateTime.now().add(const Duration(days: 5));

      final urgentScore = aiService.calculatePriorityScore(urgentDeadline, 120, 'High', 'High');
      final distantScore = aiService.calculatePriorityScore(distantDeadline, 30, 'Low', 'Low');

      expect(urgentScore, greaterThan(distantScore));
    });

    test('Score should stay within 0.0 and 100.0 limits', () {
      final distantDeadline = DateTime.now().add(const Duration(days: 30));
      final lowScore = aiService.calculatePriorityScore(distantDeadline, 5, 'Low', 'Low');

      expect(lowScore, greaterThanOrEqualTo(0.0));
      expect(lowScore, lessThanOrEqualTo(100.0));
    });
  });

  group('AiService Scheduler Tests', () {
    final aiService = AiService();

    test('Scheduler should sequence tasks based on priority score', () {
      final now = DateTime.now();
      final tasks = [
        Task(
          id: '1',
          title: 'Low Priority',
          description: '',
          deadline: now.add(const Duration(days: 5)),
          durationMinutes: 30,
          complexity: 'Low',
          energyRequired: 'Low',
          priorityScore: 10.0,
        ),
        Task(
          id: '2',
          title: 'High Priority',
          description: '',
          deadline: now.add(const Duration(hours: 1)),
          durationMinutes: 60,
          complexity: 'High',
          energyRequired: 'High',
          priorityScore: 90.0,
        ),
      ];

      final scheduled = aiService.suggestSchedule(tasks);

      // Verify task '2' starts before task '1'
      final task1 = scheduled.firstWhere((t) => t.id == '1');
      final task2 = scheduled.firstWhere((t) => t.id == '2');

      expect(task2.scheduledStartTime, isNotNull);
      expect(task1.scheduledStartTime, isNotNull);
      expect(task2.scheduledStartTime!.isBefore(task1.scheduledStartTime!), isTrue);
    });
  });
}
