import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/goal_model.dart';

class AiService {
  String? _apiKey;

  AiService({String? apiKey}) {
    _apiKey = apiKey;
  }

  void updateApiKey(String? key) {
    _apiKey = key;
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;

  /// Computes a smart priority score (0.0 to 100.0) based on deadline, duration, complexity, and energy level.
  double calculatePriorityScore(
    DateTime deadline,
    int durationMinutes,
    String complexity,
    String energyRequired,
  ) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    final hoursRemaining = difference.inHours;

    // 1. Urgency factor: base score increases as the deadline approaches.
    double urgencyFactor;
    if (hoursRemaining <= 0) {
      urgencyFactor = 100.0;
    } else if (hoursRemaining < 3) {
      urgencyFactor = 90.0;
    } else if (hoursRemaining < 12) {
      urgencyFactor = 75.0;
    } else if (hoursRemaining < 24) {
      urgencyFactor = 55.0;
    } else if (hoursRemaining < 48) {
      urgencyFactor = 35.0;
    } else if (hoursRemaining < 168) {
      urgencyFactor = 15.0;
    } else {
      urgencyFactor = 5.0;
    }

    // 2. Workload factor
    double workloadFactor = 1.0;
    if (hoursRemaining > 0) {
      final taskHours = durationMinutes / 60.0;
      final ratio = taskHours / hoursRemaining;
      if (ratio > 0.8) {
        workloadFactor = 2.5;
      } else if (ratio > 0.5) {
        workloadFactor = 1.8;
      } else if (ratio > 0.3) {
        workloadFactor = 1.4;
      }
    }

    // 3. Complexity weight
    double complexityWeight;
    switch (complexity.toLowerCase()) {
      case 'high':
        complexityWeight = 1.3;
      case 'medium':
        complexityWeight = 1.0;
      case 'low':
      default:
        complexityWeight = 0.8;
    }

    // 4. Energy weight
    double energyWeight;
    switch (energyRequired.toLowerCase()) {
      case 'high':
        energyWeight = 1.2;
      case 'medium':
        energyWeight = 1.0;
      case 'low':
      default:
        energyWeight = 0.9;
    }

    double score = urgencyFactor * workloadFactor * complexityWeight * energyWeight;

    if (score > 100.0) score = 100.0;
    if (score < 0.0) score = 0.0;

    return double.parse(score.toStringAsFixed(1));
  }

  /// Automatically schedules uncompleted tasks sequentially in the next available slots.
  List<Task> suggestSchedule(List<Task> tasks, {DateTime? startingFrom}) {
    final uncompleted = tasks.where((t) => !t.isCompleted).toList();
    uncompleted.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    final scheduledTasks = <Task>[];
    var currentSlotTime = startingFrom ?? DateTime.now();

    int minutes = currentSlotTime.minute;
    if (minutes > 0 && minutes <= 15) {
      currentSlotTime = currentSlotTime.add(Duration(minutes: 15 - minutes));
    } else if (minutes > 15 && minutes <= 30) {
      currentSlotTime = currentSlotTime.add(Duration(minutes: 30 - minutes));
    } else if (minutes > 30 && minutes <= 45) {
      currentSlotTime = currentSlotTime.add(Duration(minutes: 45 - minutes));
    } else if (minutes > 45) {
      currentSlotTime = currentSlotTime.add(Duration(minutes: 60 - minutes));
    }
    
    currentSlotTime = DateTime(
      currentSlotTime.year,
      currentSlotTime.month,
      currentSlotTime.day,
      currentSlotTime.hour,
      currentSlotTime.minute,
    );

    for (var task in uncompleted) {
      if (currentSlotTime.hour >= 22) {
        currentSlotTime = DateTime(
          currentSlotTime.year,
          currentSlotTime.month,
          currentSlotTime.day + 1,
          8,
          0,
        );
      } else if (currentSlotTime.hour < 8) {
        currentSlotTime = DateTime(
          currentSlotTime.year,
          currentSlotTime.month,
          currentSlotTime.day,
          8,
          0,
        );
      }

      scheduledTasks.add(task.copyWith(scheduledStartTime: currentSlotTime));
      currentSlotTime = currentSlotTime.add(Duration(minutes: task.durationMinutes));
      currentSlotTime = currentSlotTime.add(const Duration(minutes: 10));
    }

    final completed = tasks.where((t) => t.isCompleted).toList();
    return [...completed, ...scheduledTasks];
  }

  /// AI Goal Breakdown: Generates actionable subtasks using Gemini API or local fallback.
  Future<List<GoalSubtask>> decomposeGoal(String title, String description) async {
    if (hasApiKey) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey!,
          generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        );

        final prompt = 'Decompose the goal "$title" with description "$description" into 5 actionable, progressive subtasks. '
            'Return the output as a strict JSON array of objects. Each object must have exactly keys "title" (short milestone title) and "description" (what to do in 1 sentence). '
            'Do not wrap in markdown or any code fence. Example format: [{"title": "Setup", "description": "Initialize app"}]';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        final responseText = response.text;

        if (responseText != null) {
          final List<dynamic> decoded = jsonDecode(responseText.trim());
          return decoded.map((item) {
            return GoalSubtask(
              title: item['title'] as String? ?? 'New Milestone',
              description: item['description'] as String? ?? 'Tackle this goal step.',
            );
          }).toList();
        }
      } catch (_) {
        // Fallback to local on API failure
      }
    }

    // Local Fallback
    final lowercaseTitle = title.toLowerCase();

    if (lowercaseTitle.contains('exam') || lowercaseTitle.contains('study') || lowercaseTitle.contains('test')) {
      return [
        const GoalSubtask(title: "Collect Study Material & Syllabus", description: "Gather lecture slides, notes, text books, and exam documents.", status: 'In Progress'),
        const GoalSubtask(title: "Create Topic-wise Revision Plan", description: "Break the syllabus into daily chunks and schedule reviews."),
        const GoalSubtask(title: "Practice Active Recall & Flashcards", description: "Convert key definitions and hard concepts into flashcards to self-test."),
        const GoalSubtask(title: "Solve Mock Question Papers", description: "Set a timer and solve 2-3 previous papers to test speed and accuracy."),
        const GoalSubtask(title: "Final Formula & Concept Review", description: "Briefly review cheat sheets and sleep well the night before the exam."),
      ];
    } else if (lowercaseTitle.contains('hackathon') || lowercaseTitle.contains('app') || lowercaseTitle.contains('project') || lowercaseTitle.contains('develop')) {
      return [
        const GoalSubtask(title: "Wireframing & Core Architecture Design", description: "Sketch the main screens and map out the BLoC state management.", status: 'In Progress'),
        const GoalSubtask(title: "Set Up Project & Dependency Packages", description: "Initialize Flutter app, customize pubspec.yaml, and folder tree."),
        const GoalSubtask(title: "Build Core Features & UI Screens", description: "Implement primary dashboards, logic services, widgets, and timers."),
        const GoalSubtask(title: "Implement AI Simulation & Integrations", description: "Code the priority computation algorithms and assistants."),
        const GoalSubtask(title: "Aesthetics Refinement & User Testing", description: "Polishing micro-interactions, neon gradients, and fixing bugs."),
      ];
    } else if (lowercaseTitle.contains('health') || lowercaseTitle.contains('fitness') || lowercaseTitle.contains('workout') || lowercaseTitle.contains('gym')) {
      return [
        const GoalSubtask(title: "Define Fitness Targets & Schedule", description: "Decide on targets (e.g., lose 2kg, run 5k) and block workout times.", status: 'In Progress'),
        const GoalSubtask(title: "Draft a Nutrient-Rich Meal Plan", description: "List healthy grocieries, prep weekly snacks, and track proteins."),
        const GoalSubtask(title: "Execute Weekly Workout Routine", description: "Perform 3 strength training sessions and 2 cardio runs."),
        const GoalSubtask(title: "Monitor Sleep and Hydration", description: "Aim for 8 hours of sleep and drink 3 liters of water daily."),
        const GoalSubtask(title: "Track Weekly Progress & Milestones", description: "Measure body metrics and adjust exercise intensity based on gains."),
      ];
    }

    return [
      GoalSubtask(title: "Define Objectives & Scope for '$title'", description: "Specify exactly what success looks like and identify constraints.", status: 'In Progress'),
      const GoalSubtask(title: "Gather Necessary Resources & Tools", description: "Compile documents, applications, templates, or kits required."),
      const GoalSubtask(title: "Draft Initial Outline / Prototype", description: "Build a rough draft, sketch, or basic skeleton of the project."),
      const GoalSubtask(title: "Execute & Implement Core Tasks", description: "Focus on the heaviest components of the goal to make maximum progress."),
      const GoalSubtask(title: "Review, Refine & Finalize", description: "Double check quality, polish formatting, and confirm it meets requirements."),
    ];
  }

  /// AI Assistant Voice Command Interpreter: parses custom inputs using Gemini or local fallback.
  Future<Map<String, dynamic>> interpretVoiceCommand(String query) async {
    if (hasApiKey) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: _apiKey!,
          generationConfig: GenerationConfig(responseMimeType: 'application/json'),
        );

        final prompt = 'You are the conversational AI assistant for "The Last-Minute Life Saver" productivity app. '
            'Analyze this message from the user: "$query". '
            'Respond with a strict JSON object containing: '
            '1. "reply" (String): A friendly, helpful conversational reply that is brief. '
            '2. "action" (String): One of: '
            '   - "schedule" (if they want to optimize/schedule tasks) '
            '   - "recommend_next" (if they ask what they should do next or what is next) '
            '   - "focus_top" (if they want to start a timer/focus mode) '
            '   - "add_task" (if they want to create/add a new task) '
            '   - "none" (for regular chitchat) '
            '3. "task_title" (String): The extracted title of the task if action is "add_task" (capitalized). '
            '4. "due" (String): The deadline keyword if action is "add_task". Must be either "today", "tomorrow", or "next_week". '
            'Return ONLY the raw JSON object. Do not format in markdown code fences. Example: {"reply": "Done!", "action": "schedule"}';

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        final responseText = response.text;

        if (responseText != null) {
          final Map<String, dynamic> decoded = jsonDecode(responseText.trim());
          
          final action = decoded['action'] as String? ?? 'none';
          final reply = decoded['reply'] as String? ?? 'I can assist with that!';

          if (action == 'add_task') {
            final title = decoded['task_title'] as String? ?? 'New Task';
            final due = decoded['due'] as String? ?? 'tomorrow';
            
            DateTime deadline = DateTime.now().add(const Duration(days: 1));
            if (due == 'today') {
              deadline = DateTime.now().add(const Duration(hours: 6));
            } else if (due == 'next_week') {
              deadline = DateTime.now().add(const Duration(days: 7));
            }

            return {
              'action': 'add_task',
              'title': title,
              'deadline': deadline,
              'duration': 45,
              'complexity': 'Medium',
              'energy': 'Medium',
              'reply': reply,
            };
          }

          return {
            'action': action,
            'reply': reply,
          };
        }
      } catch (_) {
        // Fallback to local on API failure
      }
    }

    // Local Fallback
    final input = query.toLowerCase();

    if (input.contains('schedule') || input.contains('optimize') || input.contains('arrange')) {
      return {
        'action': 'schedule',
        'reply': "I have analyzed your workload and deadlines. Let's optimize your schedule! I am arranging your tasks by priority score to ensure you complete the most urgent ones first.",
      };
    }

    if (input.contains('next') || input.contains('do now') || input.contains('should i do')) {
      return {
        'action': 'recommend_next',
        'reply': "Looking at your schedule, you have a task due soon that demands high energy. I recommend starting the top task on your dashboard now. Would you like me to start the Pomodoro focus timer?",
      };
    }

    if (input.contains('focus') || input.contains('timer') || input.contains('pomodoro')) {
      return {
        'action': 'focus_top',
        'reply': "Setting focus mode. I'm opening the immersive Pomodoro screen for your highest priority task. Let's block out distractions for the next 25 minutes!",
      };
    }

    if (input.contains('add task') || input.contains('create task') || input.contains('new task')) {
      String title = "New AI Task";
      final regex = RegExp(r'(?:add task|create task|new task)\s+([a-zA-Z0-9\s]+?)(?:\s+(?:due|by|tomorrow|today)|$)');
      final match = regex.firstMatch(input);
      if (match != null && match.groupCount >= 1) {
        title = match.group(1)!.trim();
        title = title.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
      }

      DateTime deadline = DateTime.now().add(const Duration(days: 1));
      String dueStr = "tomorrow";
      if (input.contains('today')) {
        deadline = DateTime.now().add(const Duration(hours: 6));
        dueStr = "today";
      } else if (input.contains('next week')) {
        deadline = DateTime.now().add(const Duration(days: 7));
        dueStr = "next week";
      }

      return {
        'action': 'add_task',
        'title': title,
        'deadline': deadline,
        'duration': 45,
        'complexity': 'Medium',
        'energy': 'Medium',
        'reply': "Got it! I have added the task '$title' due $dueStr with Medium complexity. I will automatically calculate its priority score and add it to your schedule.",
      };
    }

    if (input.contains('hello') || input.contains('hi') || input.contains('hey')) {
      return {
        'action': 'none',
        'reply': "Hello! I am your Last-Minute Life Saver assistant. You can ask me to 'schedule my tasks', 'what should I do next?', 'add task Finish Homework due today', or 'start a focus timer'. How can I support your productivity today?",
      };
    }

    return {
      'action': 'none',
      'reply': "Interesting! I can help you action that. Try asking me to 'schedule my tasks' or 'start focus mode' to tackle your deadlines immediately.",
    };
  }

  /// Returns tailored textual recommendations based on user tasks list
  List<String> getPersonalizedRecommendations(List<Task> tasks) {
    final uncompleted = tasks.where((t) => !t.isCompleted).toList();
    if (uncompleted.isEmpty) {
      return [
        "🎉 Incredible job! All tasks are complete. Take a break to recharge.",
        "💡 Pro tip: Create a high-level Goal and let AI break it down into habits to stay consistent.",
        "🧘 Habit builder: Perform a 5-minute deep breathing session to ease cognitive load."
      ];
    }

    uncompleted.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    final topTask = uncompleted.first;

    final recommendations = <String>[];
    
    if (topTask.priorityScore > 70) {
      recommendations.add(
        "🚨 Action Required: '${topTask.title}' has a priority score of ${topTask.priorityScore}! Start a 25-minute Pomodoro session immediately to prevent missing the deadline."
      );
    } else {
      recommendations.add(
        "⚡ Next step: Let's tackle '${topTask.title}' next. It's estimated to take ${topTask.durationMinutes} minutes and requires ${topTask.energyRequired} energy."
      );
    }

    final unscheduledCount = uncompleted.where((t) => t.scheduledStartTime == null).length;
    if (unscheduledCount > 0) {
      recommendations.add(
        "📅 Schedule Gap: You have $unscheduledCount unscheduled task(s). Click 'AI Auto-Schedule' on the Calendar tab to optimize your day's layout."
      );
    }

    final highEnergyTasks = uncompleted.where((t) => t.energyRequired == 'High').length;
    if (highEnergyTasks > 2) {
      recommendations.add(
        "🧠 Energy Management: You have $highEnergyTasks High Energy tasks pending. Try working on one now while your focus levels are peak, and save Low Energy tasks for later tonight."
      );
    } else {
      recommendations.add(
        "⏱️ Procrastination Shield: Breaking tasks into micro-steps lowers the activation energy needed to start. Just do 5 minutes!"
      );
    }

    return recommendations;
  }
}
