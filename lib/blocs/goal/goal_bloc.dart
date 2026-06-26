import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/goal_model.dart';
import '../../services/ai_service.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final AiService _aiService;
  final SharedPreferences _prefs;
  static const String _storageKey = 'goals_list';

  GoalBloc(this._aiService, this._prefs) : super(GoalLoading()) {
    on<LoadGoals>(_onLoadGoals);
    on<AddGoal>(_onAddGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<UpdateSubtaskStatus>(_onUpdateSubtaskStatus);
  }

  void _onLoadGoals(LoadGoals event, Emitter<GoalState> emit) async {
    final jsonStr = _prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final goals = decoded.map((g) => Goal.fromJson(g as Map<String, dynamic>)).toList();
        emit(GoalsLoaded(goals: goals));
        return;
      } catch (_) {}
    }
    // Starts empty to remove default dummy data
    emit(const GoalsLoaded(goals: []));
  }

  void _saveToStorage(List<Goal> goals) {
    _prefs.setString(_storageKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  void _onAddGoal(AddGoal event, Emitter<GoalState> emit) async {
    if (state is GoalsLoaded) {
      final currentGoals = (state as GoalsLoaded).goals;
      
      // Request AI goal breakdown (runs either mock decomposition or calls Gemini API)
      final subtasks = await _aiService.decomposeGoal(event.title, event.description);
      
      final newGoal = Goal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title,
        description: event.description,
        targetDate: event.targetDate,
        subtasks: subtasks,
        progress: Goal.calculateProgress(subtasks),
      );

      final updated = List<Goal>.from(currentGoals)..add(newGoal);
      _saveToStorage(updated);
      emit(GoalsLoaded(goals: updated));
    }
  }

  void _onDeleteGoal(DeleteGoal event, Emitter<GoalState> emit) {
    if (state is GoalsLoaded) {
      final currentGoals = (state as GoalsLoaded).goals;
      final updatedGoals = currentGoals.where((g) => g.id != event.id).toList();
      _saveToStorage(updatedGoals);
      emit(GoalsLoaded(goals: updatedGoals));
    }
  }

  void _onUpdateSubtaskStatus(UpdateSubtaskStatus event, Emitter<GoalState> emit) {
    if (state is GoalsLoaded) {
      final currentGoals = (state as GoalsLoaded).goals;
      final updatedGoals = currentGoals.map((goal) {
        if (goal.id == event.goalId) {
          final updatedSubtasks = goal.subtasks.map((subtask) {
            if (subtask.title == event.subtaskTitle) {
              return subtask.copyWith(status: event.newStatus);
            }
            return subtask;
          }).toList();
          return goal.copyWith(
            subtasks: updatedSubtasks,
            progress: Goal.calculateProgress(updatedSubtasks),
          );
        }
        return goal;
      }).toList();
      _saveToStorage(updatedGoals);
      emit(GoalsLoaded(goals: updatedGoals));
    }
  }
}
