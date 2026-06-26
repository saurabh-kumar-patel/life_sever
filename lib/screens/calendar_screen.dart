import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';
import '../blocs/task/task_state.dart';
import '../models/task_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasksState = state as TasksLoaded;
        final allTasks = tasksState.tasks;

        // Filter tasks for selected day
        final dayTasks = allTasks.where((task) {
          if (task.scheduledStartTime == null) return false;
          final start = task.scheduledStartTime!;
          return start.year == _selectedDay.year &&
              start.month == _selectedDay.month &&
              start.day == _selectedDay.day;
        }).toList();

        // Sort by start time
        dayTasks.sort((a, b) => a.scheduledStartTime!.compareTo(b.scheduledStartTime!));

        final unscheduledTasks = allTasks.where((t) => t.scheduledStartTime == null && !t.isCompleted).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar Screen Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DAILY PLANNER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _triggerAutoSchedule(context),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text(
                        'AI AUTO-SCHEDULE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A2BE2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Day Selector
              _buildDayPicker(),

              const SizedBox(height: 12),

              // Main content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hour guide + Timeline blocks
                    Expanded(
                      flex: 3,
                      child: _buildTimelineView(dayTasks),
                    ),

                    // Unscheduled sidebar
                    if (unscheduledTasks.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: _buildUnscheduledSidebar(unscheduledTasks),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayPicker() {
    final now = DateTime.now();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = now.add(Duration(days: index - 2)); // Show a range: 2 days back, 5 days forward
          final isSelected = day.year == _selectedDay.year &&
              day.month == _selectedDay.month &&
              day.day == _selectedDay.day;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              width: 50,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF8A2BE2), Color(0xFF00E5FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF161625),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : const Color(0x13FFFFFF),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[500],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[200],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineView(List<Task> dayTasks) {
    // We display working hours: 8 AM to 10 PM
    final startHour = 8;
    final endHour = 22;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: endHour - startHour + 1,
        itemBuilder: (context, index) {
          final hour = startHour + index;
          final timeLabel = DateFormat('h a').format(DateTime(2026, 1, 1, hour));

          // Find tasks that start in this hour
          final tasksInHour = dayTasks.where((t) => t.scheduledStartTime!.hour == hour).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Label
                    SizedBox(
                      width: 50,
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Task Blocks
                    Expanded(
                      child: tasksInHour.isEmpty
                          ? Container(
                              height: 36,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0x0CFFFFFF), width: 1),
                                ),
                              ),
                            )
                          : Column(
                              children: tasksInHour.map((task) {
                                return _buildTaskBlockWidget(task);
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskBlockWidget(Task task) {
    final startTimeStr = DateFormat('h:mm a').format(task.scheduledStartTime!);
    final endTime = task.scheduledStartTime!.add(Duration(minutes: task.durationMinutes));
    final endTimeStr = DateFormat('h:mm a').format(endTime);

    // Color code priority
    Color priorityColor;
    if (task.priorityScore > 75) {
      priorityColor = const Color(0xFFFF5722); // Critical
    } else if (task.priorityScore > 40) {
      priorityColor = const Color(0xFF00E5FF); // High/Medium
    } else {
      priorityColor = const Color(0xFF8A2BE2); // Low
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B2D),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$startTimeStr - $endTimeStr',
                style: TextStyle(color: Colors.grey[500], fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            task.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUnscheduledSidebar(List<Task> unscheduled) {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161625),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x13FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNSCHEDULED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: unscheduled.length,
              itemBuilder: (context, index) {
                final task = unscheduled[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${task.durationMinutes}m • ${task.complexity}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 9),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showSchedulePicker(context, task);
                            },
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFF00E5FF),
                              size: 14,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _triggerAutoSchedule(BuildContext context) {
    // Show a premium glassmorphic thinking dialog before applying scheduling
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final taskBloc = context.read<TaskBloc>();
        final messenger = ScaffoldMessenger.of(context);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (ctx.mounted) {
            Navigator.pop(ctx);
          }
          taskBloc.add(AutoScheduleTasks());
          
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF8A2BE2),
              content: Text(
                '🔮 AI Scheduler arranged your day by deadline and energy level!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF131320),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF00E5FF)),
              const SizedBox(height: 20),
              const Text(
                'AI CO-PILOT SCHEDULER',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing deadlines, estimated durations, and energy profiles to build your stress-free day...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSchedulePicker(BuildContext context, Task task) {
    // Prompt to quickly select a time slot
    showDialog(
      context: context,
      builder: (ctx) {
        final now = DateTime.now();
        return SimpleDialog(
          backgroundColor: const Color(0xFF161625),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Schedule "${task.title}"',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<TaskBloc>().add(UpdateTaskSchedule(
                  task.id,
                  DateTime(now.year, now.month, now.day, 9, 0),
                ));
              },
              child: const Text('Schedule for 9:00 AM today', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<TaskBloc>().add(UpdateTaskSchedule(
                  task.id,
                  DateTime(now.year, now.month, now.day, 14, 0),
                ));
              },
              child: const Text('Schedule for 2:00 PM today', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<TaskBloc>().add(UpdateTaskSchedule(
                  task.id,
                  DateTime(now.year, now.month, now.day, 17, 0),
                ));
              },
              child: const Text('Schedule for 5:00 PM today', style: TextStyle(color: Color(0xFF00E5FF))),
            ),
          ],
        );
      },
    );
  }
}
