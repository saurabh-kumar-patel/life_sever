import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final String id;
  final String title;
  final String category; // 'Health', 'Work', 'Study', 'Personal'
  final int streak;
  final DateTime? lastCompleted;
  final bool isCompletedToday;

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    this.streak = 0,
    this.lastCompleted,
    this.isCompletedToday = false,
  });

  Habit copyWith({
    String? id,
    String? title,
    String? category,
    int? streak,
    DateTime? lastCompleted,
    bool? isCompletedToday,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'streak': streak,
      'lastCompleted': lastCompleted?.toIso8601String(),
      'isCompletedToday': isCompletedToday,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      streak: json['streak'] as int? ?? 0,
      lastCompleted: json['lastCompleted'] != null
          ? DateTime.parse(json['lastCompleted'] as String)
          : null,
      isCompletedToday: json['isCompletedToday'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        streak,
        lastCompleted,
        isCompletedToday,
      ];
}
