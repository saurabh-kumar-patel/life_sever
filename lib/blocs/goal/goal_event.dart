import 'package:equatable/equatable.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalEvent {}

class AddGoal extends GoalEvent {
  final String title;
  final String description;
  final DateTime targetDate;

  const AddGoal({
    required this.title,
    required this.description,
    required this.targetDate,
  });

  @override
  List<Object?> get props => [title, description, targetDate];
}

class DeleteGoal extends GoalEvent {
  final String id;

  const DeleteGoal(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateSubtaskStatus extends GoalEvent {
  final String goalId;
  final String subtaskTitle;
  final String newStatus; // 'Pending', 'In Progress', 'Done'

  const UpdateSubtaskStatus({
    required this.goalId,
    required this.subtaskTitle,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [goalId, subtaskTitle, newStatus];
}
