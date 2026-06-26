import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskLoading extends TaskState {}

class TasksLoaded extends TaskState {
  final List<Task> tasks;

  const TasksLoaded({this.tasks = const []});

  @override
  List<Object?> get props => [tasks];
}
