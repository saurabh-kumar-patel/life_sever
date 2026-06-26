import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final int durationMinutes;
  final String complexity; // 'Low', 'Medium', 'High'
  final String energyRequired; // 'Low', 'Medium', 'High'
  final bool isCompleted;
  final DateTime? scheduledStartTime;
  final double priorityScore; // Calculated dynamic priority score

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.durationMinutes,
    required this.complexity,
    required this.energyRequired,
    this.isCompleted = false,
    this.scheduledStartTime,
    this.priorityScore = 0.0,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    int? durationMinutes,
    String? complexity,
    String? energyRequired,
    bool? isCompleted,
    DateTime? scheduledStartTime,
    double? priorityScore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      complexity: complexity ?? this.complexity,
      energyRequired: energyRequired ?? this.energyRequired,
      isCompleted: isCompleted ?? this.isCompleted,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      priorityScore: priorityScore ?? this.priorityScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'durationMinutes': durationMinutes,
      'complexity': complexity,
      'energyRequired': energyRequired,
      'isCompleted': isCompleted,
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'priorityScore': priorityScore,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      durationMinutes: json['durationMinutes'] as int,
      complexity: json['complexity'] as String,
      energyRequired: json['energyRequired'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      scheduledStartTime: json['scheduledStartTime'] != null
          ? DateTime.parse(json['scheduledStartTime'] as String)
          : null,
      priorityScore: (json['priorityScore'] as num? ?? 0.0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        deadline,
        durationMinutes,
        complexity,
        energyRequired,
        isCompleted,
        scheduledStartTime,
        priorityScore,
      ];
}
