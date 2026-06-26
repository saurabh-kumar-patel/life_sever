import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';
import '../blocs/task/task_state.dart';
import '../blocs/focus/focus_bloc.dart';
import '../blocs/focus/focus_event.dart';
import '../blocs/focus/focus_state.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/smart_nudge_toast.dart';
import 'calendar_screen.dart';
import 'goals_habits_screen.dart';
import 'focus_screen.dart';
import 'settings_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final AiService aiService;
  final SharedPreferences prefs;

  const DashboardScreen({
    super.key,
    required this.aiService,
    required this.prefs,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0;
  
  // Proactive notification overlay state
  Task? _nudgeTask;
  Timer? _nudgeTimer;

  // Screens corresponding to tabs
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      DashboardView(aiService: widget.aiService),
      const CalendarScreen(),
      const GoalsHabitsScreen(),
    ];
    _startProactiveNudgeScheduler();
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    super.dispose();
  }

  void _startProactiveNudgeScheduler() {
    // Check every 30 seconds for critical pending tasks to nudge the user
    _nudgeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) return;
      final taskState = context.read<TaskBloc>().state;
      final focusState = context.read<FocusBloc>().state;

      // Only nudge if not already in a focus session, and no nudge is visible
      if (focusState is FocusIdle && _nudgeTask == null) {
        if (taskState is TasksLoaded) {
          final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();
          if (pendingTasks.isNotEmpty) {
            // Find most critical task
            pendingTasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
            final topCritical = pendingTasks.first;

            // Nudge if priority score is high (>65)
            if (topCritical.priorityScore > 65) {
              setState(() {
                _nudgeTask = topCritical;
              });
            }
          }
        }
      }
    });
  }

  void _handleNudgeAction() {
    if (_nudgeTask != null) {
      // Start focus timer for this task
      context.read<FocusBloc>().add(StartFocus(task: _nudgeTask!, durationMinutes: 25));
      setState(() {
        _nudgeTask = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FocusBloc, FocusState>(
      listenWhen: (previous, current) => previous is! FocusRunning && current is FocusRunning,
      listener: (context, state) {
        if (state is FocusRunning) {
          // If focus is started (e.g. from chatbot), route immediately
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FocusScreen()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0C0C12), Color(0xFF141424)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Active Screen Body
                Column(
                  children: [
                    // Shared App Bar
                    _buildAppBar(),
                    
                    Expanded(
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: _tabs,
                      ),
                    ),
                  ],
                ),

                // Slide-up Smart Nudge Overlay
                if (_nudgeTask != null)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: SmartNudgeToast(
                      task: _nudgeTask!,
                      onAction: _handleNudgeAction,
                      onDismiss: () {
                        setState(() {
                          _nudgeTask = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Floating mic button for AI Assistant
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openVoiceAssistant(context),
          backgroundColor: const Color(0xFF00E5FF),
          foregroundColor: Colors.black,
          child: const Icon(Icons.mic, size: 28),
        ),
        
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'LIFESAVER AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () => _openSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.grey),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  void _openSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        aiService: widget.aiService,
        prefs: widget.prefs,
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131320),
        border: Border(top: BorderSide(color: Color(0x0CFFFFFF), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey[650],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            activeIcon: Icon(Icons.dashboard_customize, color: Color(0xFF00E5FF)),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today, color: Color(0xFF00E5FF)),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            activeIcon: Icon(Icons.auto_awesome_mosaic, color: Color(0xFF00E5FF)),
            label: 'Goals & Habits',
          ),
        ],
      ),
    );
  }

  void _openVoiceAssistant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiChatSheet(aiService: widget.aiService),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'The Last-Minute Life Saver',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.flash_on, color: Color(0xFF00E5FF), size: 40),
      children: [
        const Text(
          'An AI-powered productivity companion built for Vibe2Ship Hackathon.\n\n'
          'Features dynamic prioritization, scheduling models, goal decomposition, habits check lists, and a Pomodoro helper.',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

// --- DASHBOARD VIEW (TAB 1 CONTENT) ---
class DashboardView extends StatelessWidget {
  final AiService aiService;

  const DashboardView({super.key, required this.aiService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasksState = state as TasksLoaded;
        final tasks = tasksState.tasks;
        final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
        final completedTasks = tasks.where((t) => t.isCompleted).toList();

        // Sort pending tasks by priority score descending
        pendingTasks.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

        // Get AI recommendation text
        final recommendations = aiService.getPersonalizedRecommendations(tasks);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Progress Header Card
            _buildMetricsHeaderCard(completedTasks.length, tasks.length),

            const SizedBox(height: 16),

            // AI Productivity Insights banner
            _buildAiRecommendationBanner(recommendations),

            const SizedBox(height: 18),

            // Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_bulleted, color: Color(0xFF8A2BE2), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'SMART PRIORITIZED TASKS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddTaskDialog(context),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF00E5FF)),
                  label: const Text('ADD TASK', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 11)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF161625),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tasks List
            pendingTasks.isEmpty
                ? _buildEmptyStateWidget()
                : Column(
                    children: pendingTasks.map((task) {
                      return _buildTaskItemCard(context, task);
                    }).toList(),
                  ),
            
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildMetricsHeaderCard(int completedCount, int totalCount) {
    final double completionRatio = totalCount > 0 ? completedCount / totalCount : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E34), Color(0xFF11111E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x13FFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR DEADLINE SHIELD',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Protecting your commitments',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedCount of $totalCount tasks completed today',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          
          // Radial Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: completionRatio,
                  strokeWidth: 5,
                  color: const Color(0xFF8A2BE2),
                  backgroundColor: const Color(0x1F8A2BE2),
                ),
              ),
              Text(
                '${(completionRatio * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationBanner(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131323),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
              SizedBox(width: 8),
              Text(
                'AI COPILOT RECOMMENDATION',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: Colors.grey[300], fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaskItemCard(BuildContext context, Task task) {
    // Formatted Time remaining
    final diff = task.deadline.difference(DateTime.now());
    String timeRemaining;
    Color timeColor = Colors.grey[400]!;

    if (diff.isNegative) {
      timeRemaining = "Overdue";
      timeColor = const Color(0xFFFF5722);
    } else if (diff.inHours < 1) {
      timeRemaining = "Due in ${diff.inMinutes}m";
      timeColor = const Color(0xFFFF5722);
    } else if (diff.inHours < 24) {
      timeRemaining = "Due in ${diff.inHours}h";
      timeColor = const Color(0xFFFF5722);
    } else {
      timeRemaining = "Due in ${diff.inDays}d";
    }

    // Color code priority gauge
    Color priorityColor;
    if (task.priorityScore > 75) {
      priorityColor = const Color(0xFFFF5722); // Critical
    } else if (task.priorityScore > 40) {
      priorityColor = const Color(0xFF00E5FF); // High
    } else {
      priorityColor = const Color(0xFF8A2BE2); // Low
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          // Launch focus mode
          context.read<FocusBloc>().add(StartFocus(task: task, durationMinutes: 25));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Check completion button
              GestureDetector(
                onTap: () {
                  context.read<TaskBloc>().add(ToggleTaskComplete(task.id));
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[600]!, width: 1.5),
                  ),
                  child: const Icon(Icons.check, color: Colors.transparent, size: 16),
                ),
              ),
              const SizedBox(width: 14),

              // Task Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeRemaining,
                          style: TextStyle(color: timeColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[650]),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.hourglass_empty, color: Colors.grey[600], size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${task.durationMinutes}m',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),

              // Priority Score Gauge
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: priorityColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Text(
                      '${task.priorityScore.toInt()}',
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PRIORITY',
                    style: TextStyle(color: Colors.grey[600], fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF131320),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF00E5FF),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'DEADLINE SECURED',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All your tasks have been completed. Proactively add a new task or talk to AI Copilot to schedule your day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController(text: '45');
    String complexity = 'Medium';
    String energy = 'Medium';
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161625),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Critical Task', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Task Description',
                    labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Estimated Duration (minutes)',
                    labelStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
                  ),
                ),
                const SizedBox(height: 16),

                // Deadline selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deadline: ${DateFormat('MMM d, h:mm a').format(selectedDeadline)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          if (!context.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDeadline),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              selectedDeadline = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: const Text('Select', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                
                // Complexity Selection
                const Text('Complexity Level', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Low', 'Medium', 'High'].map((comp) {
                    final isSelected = comp == complexity;
                    return ChoiceChip(
                      label: Text(comp, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8A2BE2),
                      backgroundColor: const Color(0xFF1F1F32),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                      onSelected: (bool selected) {
                        if (selected) {
                          setDialogState(() {
                            complexity = comp;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Energy level
                const Text('Energy Required', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Low', 'Medium', 'High'].map((eng) {
                    final isSelected = eng == energy;
                    return ChoiceChip(
                      label: Text(eng, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF8A2BE2),
                      backgroundColor: const Color(0xFF1F1F32),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                      onSelected: (bool selected) {
                        if (selected) {
                          setDialogState(() {
                            energy = eng;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final duration = int.tryParse(durationController.text) ?? 45;
                  context.read<TaskBloc>().add(AddTask(
                    title: titleController.text,
                    description: descController.text,
                    deadline: selectedDeadline,
                    durationMinutes: duration,
                    complexity: complexity,
                    energyRequired: energy,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('ADD TASK', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
