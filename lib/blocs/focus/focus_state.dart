import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

abstract class FocusState extends Equatable {
  const FocusState();

  @override
  List<Object?> get props => [];
}

class FocusIdle extends FocusState {}

class FocusRunning extends FocusState {
  final Task task;
  final int durationTotalSeconds;
  final int secondsRemaining;
  final bool isPaused;

  const FocusRunning({
    required this.task,
    required this.durationTotalSeconds,
    required this.secondsRemaining,
    required this.isPaused,
  });

  double get progress => durationTotalSeconds > 0 
      ? (durationTotalSeconds - secondsRemaining) / durationTotalSeconds 
      : 0.0;

  @override
  List<Object?> get props => [task, durationTotalSeconds, secondsRemaining, isPaused];
}

class FocusFinished extends FocusState {
  final Task task;

  const FocusFinished(this.task);

  @override
  List<Object?> get props => [task];
}
