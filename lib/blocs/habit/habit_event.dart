import 'package:equatable/equatable.dart';

abstract class HabitEvent extends Equatable {
  const HabitEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabits extends HabitEvent {}

class AddHabit extends HabitEvent {
  final String title;
  final String category;

  const AddHabit({required this.title, required this.category});

  @override
  List<Object?> get props => [title, category];
}

class ToggleHabitComplete extends HabitEvent {
  final String id;

  const ToggleHabitComplete(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteHabit extends HabitEvent {
  final String id;

  const DeleteHabit(this.id);

  @override
  List<Object?> get props => [id];
}
