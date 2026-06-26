import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/goal/goal_bloc.dart';
import '../blocs/goal/goal_event.dart';
import '../blocs/goal/goal_state.dart';
import '../blocs/habit/habit_bloc.dart';
import '../blocs/habit/habit_event.dart';
import '../blocs/habit/habit_state.dart';
import '../models/goal_model.dart';
import '../models/habit_model.dart';

class GoalsHabitsScreen extends StatefulWidget {
  const GoalsHabitsScreen({super.key});

  @override
  State<GoalsHabitsScreen> createState() => _GoalsHabitsScreenState();
}

class _GoalsHabitsScreenState extends State<GoalsHabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00E5FF),
            labelColor: const Color(0xFF00E5FF),
            unselectedLabelColor: Colors.grey[500],
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(child: Text('AI GOALS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2))),
              Tab(child: Text('HABITS & ROUTINES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2))),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          GoalsTab(),
          HabitsTab(),
        ],
      ),
    );
  }
}

// --- GOALS TAB WIDGET ---
class GoalsTab extends StatefulWidget {
  const GoalsTab({super.key});

  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        if (state is GoalLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final goals = (state as GoalsLoaded).goals;

        return Column(
          children: [
            // Header Add Button Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI GOAL DECOMPOSITION',
                    style: TextStyle(
                      color: Color(0xFF8A2BE2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddGoalDialog(context),
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF00E5FF)),
                    label: const Text('NEW GOAL', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11)),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF161625),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: goals.isEmpty
                  ? Center(child: Text('No goals set yet. Tap "NEW GOAL" to decompose a new objective!', style: TextStyle(color: Colors.grey[600], fontSize: 12)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        return _buildGoalCard(goal);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalCard(Goal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: const Color(0xFF00E5FF),
        collapsedIconColor: Colors.grey,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                ),
                Text(
                  'Due ${DateFormat('MMM d').format(goal.targetDate)}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              goal.description,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 6,
                      color: const Color(0xFF8A2BE2),
                      backgroundColor: const Color(0x1F8A2BE2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF131320),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'AI DECOMPOSED MILESTONES',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...goal.subtasks.map((subtask) => _buildSubtaskItem(goal.id, subtask)),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                    onPressed: () {
                      context.read<GoalBloc>().add(DeleteGoal(goal.id));
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtaskItem(String goalId, GoalSubtask subtask) {
    Color statusColor;
    IconData statusIcon;
    switch (subtask.status) {
      case 'Done':
        statusColor = const Color(0xFF00E676);
        statusIcon = Icons.check_circle_rounded;
      case 'In Progress':
        statusColor = const Color(0xFF00E5FF);
        statusIcon = Icons.pending_rounded;
      case 'Pending':
      default:
        statusColor = Colors.grey[600]!;
        statusIcon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Rotate status cycle: Pending -> In Progress -> Done -> Pending
              String newStatus = 'Pending';
              if (subtask.status == 'Pending') {
                newStatus = 'In Progress';
              } else if (subtask.status == 'In Progress') {
                newStatus = 'Done';
              }
              context.read<GoalBloc>().add(UpdateSubtaskStatus(
                goalId: goalId,
                subtaskTitle: subtask.title,
                newStatus: newStatus,
              ));
            },
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtask.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    decoration: subtask.status == 'Done' ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtask.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161625),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add AI Goal Breakdown', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Goal Title (e.g. Flutter Hackathon)',
                  labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Brief Description',
                  labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: ${DateFormat('MMM d, yyyy').format(selectedDate)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Select Date', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<GoalBloc>().add(AddGoal(
                    title: titleController.text,
                    description: descController.text,
                    targetDate: selectedDate,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('GENERATE BREAKDOWN', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- HABITS TAB WIDGET ---
class HabitsTab extends StatefulWidget {
  const HabitsTab({super.key});

  @override
  State<HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends State<HabitsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HabitBloc, HabitState>(
      builder: (context, state) {
        if (state is HabitLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final habits = (state as HabitsLoaded).habits;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DAILY STREAKS & ROUTINES',
                    style: TextStyle(
                      color: Color(0xFF8A2BE2),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddHabitDialog(context),
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF00E5FF)),
                    label: const Text('NEW HABIT', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11)),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF161625),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: habits.isEmpty
                  ? Center(child: Text('No habits added yet. Tap "NEW HABIT" to start consistency streaks!', style: TextStyle(color: Colors.grey[600], fontSize: 12)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.45,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return _buildHabitCard(habit);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit) {
    Color categoryColor;
    switch (habit.category.toLowerCase()) {
      case 'health':
        categoryColor = const Color(0xFF00E676);
      case 'study':
        categoryColor = const Color(0xFF8A2BE2);
      case 'work':
        categoryColor = const Color(0xFF00E5FF);
      case 'personal':
      default:
        categoryColor = const Color(0xFFE040FB);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category Chip Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: categoryColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    habit.category.toUpperCase(),
                    style: TextStyle(color: categoryColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ),

                // Streak flame icon
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 3),
                    Text(
                      '${habit.streak}d',
                      style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(
              habit.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    context.read<HabitBloc>().add(DeleteHabit(habit.id));
                  },
                  child: Icon(Icons.delete_outline, size: 16, color: Colors.grey[650]),
                ),

                // Check button
                GestureDetector(
                  onTap: () {
                    context.read<HabitBloc>().add(ToggleHabitComplete(habit.id));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: habit.isCompletedToday ? const Color(0xFF00E676) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: habit.isCompletedToday ? const Color(0xFF00E676) : Colors.grey[600]!,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: habit.isCompletedToday ? Colors.black : Colors.grey[600],
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final titleController = TextEditingController();
    String category = 'Health';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161625),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Daily Habit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Habit Title (e.g. Read for 15 mins)',
                  labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Health', 'Study', 'Work', 'Personal'].map((cat) {
                  final isSelected = cat == category;
                  return ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF8A2BE2),
                    backgroundColor: const Color(0xFF1F1F32),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                    onSelected: (bool selected) {
                      if (selected) {
                        setDialogState(() {
                          category = cat;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<HabitBloc>().add(AddHabit(
                    title: titleController.text,
                    category: category,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('CREATE HABIT', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
