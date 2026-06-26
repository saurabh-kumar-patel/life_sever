import 'package:equatable/equatable.dart';
import '../../models/habit_model.dart';

abstract class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

class HabitLoading extends HabitState {}

class HabitsLoaded extends HabitState {
  final List<Habit> habits;

  const HabitsLoaded({this.habits = const []});

  @override
  List<Object?> get props => [habits];
}
