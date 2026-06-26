import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';
import '../blocs/habit/habit_bloc.dart';
import '../blocs/habit/habit_event.dart';
import '../blocs/goal/goal_bloc.dart';
import '../blocs/goal/goal_event.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/goal_model.dart';

class SettingsDialog extends StatefulWidget {
  final AiService aiService;
  final SharedPreferences prefs;

  const SettingsDialog({
    super.key,
    required this.aiService,
    required this.prefs,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    // Load existing API key
    final savedKey = widget.prefs.getString('gemini_api_key');
    if (savedKey != null) {
      _apiKeyController.text = savedKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      widget.prefs.remove('gemini_api_key');
      widget.aiService.updateApiKey(null);
    } else {
      widget.prefs.setString('gemini_api_key', key);
      widget.aiService.updateApiKey(key);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00E676),
        content: Text(
          'Settings saved successfully!',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
    Navigator.pop(context);
  }

  void _confirmWipeData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Wipe All Local Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete all your tasks, habits, and goals. This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _wipeAllData();
            },
            child: const Text('WIPE DATA', style: TextStyle(color: Color(0xFFFF5722), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _wipeAllData() {
    // Clear SharedPreferences
    widget.prefs.remove('tasks_list');
    widget.prefs.remove('habits_list');
    widget.prefs.remove('goals_list');

    // Reload Blocs to empty states
    context.read<TaskBloc>().add(LoadTasks());
    context.read<HabitBloc>().add(LoadHabits());
    context.read<GoalBloc>().add(LoadGoals());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFFFF5722),
        content: Text('All local data wiped successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmLoadDemoData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Load Sample Demo Data?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will overwrite your current list and add sample tasks, habits, and goals for quick Vibe2Ship demonstration.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadDemoData();
            },
            child: const Text('LOAD DEMO', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _loadDemoData() {
    final now = DateTime.now();

    // 1. Demo Tasks
    final demoTasks = [
      Task(
        id: 'task_1',
        title: 'Physics Lab Report',
        description: 'Complete the thermodynamics graphs and submit the PDF write-up.',
        deadline: now.add(const Duration(hours: 3)),
        durationMinutes: 90,
        complexity: 'High',
        energyRequired: 'High',
        priorityScore: widget.aiService.calculatePriorityScore(
          now.add(const Duration(hours: 3)), 90, 'High', 'High',
        ),
      ),
      Task(
        id: 'task_2',
        title: 'Draft Pitch Deck',
        description: 'Prepare key problem/solution slides for the Vibe2Ship startup pitch.',
        deadline: now.add(const Duration(days: 1, hours: 4)),
        durationMinutes: 120,
        complexity: 'High',
        energyRequired: 'High',
        priorityScore: widget.aiService.calculatePriorityScore(
          now.add(const Duration(days: 1, hours: 4)), 120, 'High', 'High',
        ),
      ),
      Task(
        id: 'task_3',
        title: 'Pay Electricity Bill',
        description: 'Pay utility bills before late fee applies.',
        deadline: now.add(const Duration(hours: 10)),
        durationMinutes: 10,
        complexity: 'Low',
        energyRequired: 'Low',
        priorityScore: widget.aiService.calculatePriorityScore(
          now.add(const Duration(hours: 10)), 10, 'Low', 'Low',
        ),
      ),
    ];
    widget.prefs.setString('tasks_list', jsonEncode(demoTasks.map((t) => t.toJson()).toList()));

    // 2. Demo Habits
    final demoHabits = [
      const Habit(id: 'habit_1', title: "Review Today's Schedule", category: 'Study', streak: 3),
      const Habit(id: 'habit_2', title: "25-min Focused Session", category: 'Work', streak: 5),
      const Habit(id: 'habit_3', title: "Stay Hydrated (3L Water)", category: 'Personal', streak: 7),
    ];
    widget.prefs.setString('habits_list', jsonEncode(demoHabits.map((h) => h.toJson()).toList()));

    // 3. Demo Goals
    final hackSubtasks = [
      const GoalSubtask(title: "Wireframing & Core Architecture Design", description: "Sketch the main screens and BLoC structures.", status: 'In Progress'),
      const GoalSubtask(title: "Set Up Project & Dependency Packages", description: "Initialize Flutter app, customize pubspec.yaml."),
      const GoalSubtask(title: "Build Core Features & UI Screens", description: "Implement primary dashboards and Pomodoro timer."),
      const GoalSubtask(title: "Implement AI Simulation & Integrations", description: "Code the priority computation and assistant."),
      const GoalSubtask(title: "Aesthetics Refinement & User Testing", description: "Polishing micro-interactions and fix bugs."),
    ];
    final demoGoals = [
      Goal(
        id: 'goal_1',
        title: "Google Developers Hackathon",
        description: "Build a last-minute life saver productivity app using Flutter and BLoC.",
        targetDate: now.add(const Duration(days: 3)),
        subtasks: hackSubtasks,
        progress: Goal.calculateProgress(hackSubtasks),
      )
    ];
    widget.prefs.setString('goals_list', jsonEncode(demoGoals.map((g) => g.toJson()).toList()));

    // Reload Blocs
    context.read<TaskBloc>().add(LoadTasks());
    context.read<HabitBloc>().add(LoadHabits());
    context.read<GoalBloc>().add(LoadGoals());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00E5FF),
        content: Text('Demo data loaded successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131322),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0x13FFFFFF))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFF00E5FF)),
                SizedBox(width: 10),
                Text(
                  'SYSTEM CONFIGURATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Gemini API Key TextField
            const Text(
              'GEMINI AI API KEY',
              style: TextStyle(
                color: Color(0xFF8A2BE2),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter your Gemini API key (AIzaSy...)',
                hintStyle: TextStyle(color: Colors.grey[650], fontSize: 13),
                fillColor: const Color(0xFF1B1B2E),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureKey = !_obscureKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '🔑 Your API key is stored locally on your device and sent directly to Google Gemini servers.',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),

            const SizedBox(height: 24),

            // Database Management Options
            const Text(
              'DATABASE & STORAGE MANAGEMENT',
              style: TextStyle(
                color: Color(0xFF8A2BE2),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Clear Data Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmWipeData,
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('WIPE DATA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFFF5722),
                      side: const BorderSide(color: Color(0xFFE53935), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Load Demo Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirmLoadDemoData,
                    icon: const Icon(Icons.playlist_add_check, size: 16),
                    label: const Text('LOAD DEMO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B1B2E),
                      foregroundColor: const Color(0xFF00E5FF),
                      side: const BorderSide(color: Color(0xFF00E5FF), width: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Action Buttons (Cancel / Save)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE SETTINGS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
