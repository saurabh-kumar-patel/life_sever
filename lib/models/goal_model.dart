import 'package:equatable/equatable.dart';

class GoalSubtask extends Equatable {
  final String title;
  final String description;
  final String status; // 'Pending', 'In Progress', 'Done'

  const GoalSubtask({
    required this.title,
    required this.description,
    this.status = 'Pending',
  });

  GoalSubtask copyWith({
    String? title,
    String? description,
    String? status,
  }) {
    return GoalSubtask(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
    };
  }

  factory GoalSubtask.fromJson(Map<String, dynamic> json) {
    return GoalSubtask(
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  @override
  List<Object?> get props => [title, description, status];
}

class Goal extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime targetDate;
  final List<GoalSubtask> subtasks;
  final double progress; // percentage (0.0 to 1.0)

  const Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDate,
    required this.subtasks,
    this.progress = 0.0,
  });

  static double calculateProgress(List<GoalSubtask> subtasks) {
    if (subtasks.isEmpty) return 0.0;
    int doneCount = subtasks.where((s) => s.status == 'Done').length;
    int inProgressCount = subtasks.where((s) => s.status == 'In Progress').length;
    // Done = 1.0, In Progress = 0.5, Pending = 0.0
    double score = doneCount * 1.0 + inProgressCount * 0.5;
    return score / subtasks.length;
  }

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    List<GoalSubtask>? subtasks,
    double? progress,
  }) {
    final newSubtasks = subtasks ?? this.subtasks;
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      subtasks: newSubtasks,
      progress: progress ?? calculateProgress(newSubtasks),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetDate': targetDate.toIso8601String(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'progress': progress,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    final subtasksJson = json['subtasks'] as List<dynamic>? ?? [];
    final parsedSubtasks = subtasksJson
        .map((s) => GoalSubtask.fromJson(s as Map<String, dynamic>))
        .toList();
    
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetDate: DateTime.parse(json['targetDate'] as String),
      subtasks: parsedSubtasks,
      progress: (json['progress'] as num? ?? calculateProgress(parsedSubtasks)).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, title, description, targetDate, subtasks, progress];
}
