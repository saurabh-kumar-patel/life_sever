import 'package:equatable/equatable.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class AddTask extends TaskEvent {
  final String title;
  final String description;
  final DateTime deadline;
  final int durationMinutes;
  final String complexity;
  final String energyRequired;

  const AddTask({
    required this.title,
    required this.description,
    required this.deadline,
    required this.durationMinutes,
    required this.complexity,
    required this.energyRequired,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        deadline,
        durationMinutes,
        complexity,
        energyRequired,
      ];
}

class DeleteTask extends TaskEvent {
  final String id;

  const DeleteTask(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleTaskComplete extends TaskEvent {
  final String id;

  const ToggleTaskComplete(this.id);

  @override
  List<Object?> get props => [id];
}

class AutoScheduleTasks extends TaskEvent {}

class UpdateTaskSchedule extends TaskEvent {
  final String id;
  final DateTime newStartTime;

  const UpdateTaskSchedule(this.id, this.newStartTime);

  @override
  List<Object?> get props => [id, newStartTime];
}
