import 'package:equatable/equatable.dart';
import '../../models/task_model.dart';

abstract class FocusEvent extends Equatable {
  const FocusEvent();

  @override
  List<Object?> get props => [];
}

class StartFocus extends FocusEvent {
  final Task task;
  final int durationMinutes;

  const StartFocus({required this.task, this.durationMinutes = 25});

  @override
  List<Object?> get props => [task, durationMinutes];
}

class PauseFocus extends FocusEvent {}

class ResumeFocus extends FocusEvent {}

class TickFocus extends FocusEvent {}

class CancelFocus extends FocusEvent {}

class CompleteFocus extends FocusEvent {}
