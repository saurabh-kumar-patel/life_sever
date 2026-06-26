import 'package:equatable/equatable.dart';
import '../../models/goal_model.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

class GoalLoading extends GoalState {}

class GoalsLoaded extends GoalState {
  final List<Goal> goals;

  const GoalsLoaded({this.goals = const []});

  @override
  List<Object?> get props => [goals];
}
