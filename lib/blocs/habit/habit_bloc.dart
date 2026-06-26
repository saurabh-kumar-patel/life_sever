import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/habit_model.dart';
import 'habit_event.dart';
import 'habit_state.dart';

class HabitBloc extends Bloc<HabitEvent, HabitState> {
  final SharedPreferences _prefs;
  static const String _storageKey = 'habits_list';

  HabitBloc(this._prefs) : super(HabitLoading()) {
    on<LoadHabits>(_onLoadHabits);
    on<AddHabit>(_onAddHabit);
    on<ToggleHabitComplete>(_onToggleHabitComplete);
    on<DeleteHabit>(_onDeleteHabit);
  }

  void _onLoadHabits(LoadHabits event, Emitter<HabitState> emit) {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final habits = decoded.map((h) => Habit.fromJson(h as Map<String, dynamic>)).toList();
        emit(HabitsLoaded(habits: habits));
        return;
      } catch (_) {}
    }
    // Starts empty to remove default dummy data
    emit(const HabitsLoaded(habits: []));
  }

  void _saveToStorage(List<Habit> habits) {
    _prefs.setString(_storageKey, jsonEncode(habits.map((h) => h.toJson()).toList()));
  }

  void _onAddHabit(AddHabit event, Emitter<HabitState> emit) {
    if (state is HabitsLoaded) {
      final currentHabits = (state as HabitsLoaded).habits;
      final newHabit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title,
        category: event.category,
      );
      final updated = List<Habit>.from(currentHabits)..add(newHabit);
      _saveToStorage(updated);
      emit(HabitsLoaded(habits: updated));
    }
  }

  void _onToggleHabitComplete(ToggleHabitComplete event, Emitter<HabitState> emit) {
    if (state is HabitsLoaded) {
      final currentHabits = (state as HabitsLoaded).habits;
      final updatedHabits = currentHabits.map((habit) {
        if (habit.id == event.id) {
          final willBeCompleted = !habit.isCompletedToday;
          return habit.copyWith(
            isCompletedToday: willBeCompleted,
            streak: willBeCompleted ? habit.streak + 1 : (habit.streak > 0 ? habit.streak - 1 : 0),
            lastCompleted: willBeCompleted ? DateTime.now() : null,
          );
        }
        return habit;
      }).toList();
      _saveToStorage(updatedHabits);
      emit(HabitsLoaded(habits: updatedHabits));
    }
  }

  void _onDeleteHabit(DeleteHabit event, Emitter<HabitState> emit) {
    if (state is HabitsLoaded) {
      final currentHabits = (state as HabitsLoaded).habits;
      final updatedHabits = currentHabits.where((h) => h.id != event.id).toList();
      _saveToStorage(updatedHabits);
      emit(HabitsLoaded(habits: updatedHabits));
    }
  }
}
