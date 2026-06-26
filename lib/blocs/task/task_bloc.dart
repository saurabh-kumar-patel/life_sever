import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/task_model.dart';
import '../../services/ai_service.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final AiService _aiService;
  final SharedPreferences _prefs;
  static const String _storageKey = 'tasks_list';

  TaskBloc(this._aiService, this._prefs) : super(TaskLoading()) {
    on<LoadTasks>(_onLoadTasks);
    on<AddTask>(_onAddTask);
    on<DeleteTask>(_onDeleteTask);
    on<ToggleTaskComplete>(_onToggleTaskComplete);
    on<AutoScheduleTasks>(_onAutoScheduleTasks);
    on<UpdateTaskSchedule>(_onUpdateTaskSchedule);
  }

  void _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) {
    final tasksJson = _prefs.getString(_storageKey);
    if (tasksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        final tasks = decoded.map((item) => Task.fromJson(item as Map<String, dynamic>)).toList();
        emit(TasksLoaded(tasks: tasks));
        return;
      } catch (_) {
        // Fallback to empty if parse fails
      }
    }
    // Starts empty to remove default dummy data as requested
    emit(const TasksLoaded(tasks: []));
  }

  void _saveToStorage(List<Task> tasks) {
    _prefs.setString(_storageKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  void _onAddTask(AddTask event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final score = _aiService.calculatePriorityScore(
        event.deadline,
        event.durationMinutes,
        event.complexity,
        event.energyRequired,
      );

      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title,
        description: event.description,
        deadline: event.deadline,
        durationMinutes: event.durationMinutes,
        complexity: event.complexity,
        energyRequired: event.energyRequired,
        priorityScore: score,
      );

      final updatedTasks = List<Task>.from(currentTasks)..add(newTask);
      _saveToStorage(updatedTasks);
      emit(TasksLoaded(tasks: updatedTasks));
    }
  }

  void _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final updatedTasks = currentTasks.where((task) => task.id != event.id).toList();
      _saveToStorage(updatedTasks);
      emit(TasksLoaded(tasks: updatedTasks));
    }
  }

  void _onToggleTaskComplete(ToggleTaskComplete event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final updatedTasks = currentTasks.map((task) {
        if (task.id == event.id) {
          return task.copyWith(isCompleted: !task.isCompleted);
        }
        return task;
      }).toList();
      _saveToStorage(updatedTasks);
      emit(TasksLoaded(tasks: updatedTasks));
    }
  }

  void _onAutoScheduleTasks(AutoScheduleTasks event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final scheduled = _aiService.suggestSchedule(currentTasks);
      _saveToStorage(scheduled);
      emit(TasksLoaded(tasks: scheduled));
    }
  }

  void _onUpdateTaskSchedule(UpdateTaskSchedule event, Emitter<TaskState> emit) {
    if (state is TasksLoaded) {
      final currentTasks = (state as TasksLoaded).tasks;
      final updatedTasks = currentTasks.map((task) {
        if (task.id == event.id) {
          return task.copyWith(scheduledStartTime: event.newStartTime);
        }
        return task;
      }).toList();
      _saveToStorage(updatedTasks);
      emit(TasksLoaded(tasks: updatedTasks));
    }
  }
}
