import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/task/task_bloc.dart';
import 'blocs/task/task_event.dart';
import 'blocs/habit/habit_bloc.dart';
import 'blocs/habit/habit_event.dart';
import 'blocs/goal/goal_bloc.dart';
import 'blocs/goal/goal_event.dart';
import 'blocs/focus/focus_bloc.dart';
import 'services/ai_service.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('gemini_api_key');
  final aiService = AiService(apiKey: apiKey);

  runApp(MyApp(
    prefs: prefs,
    aiService: aiService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final AiService aiService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>(
          create: (context) => TaskBloc(aiService, prefs)..add(LoadTasks()),
        ),
        BlocProvider<HabitBloc>(
          create: (context) => HabitBloc(prefs)..add(LoadHabits()),
        ),
        BlocProvider<GoalBloc>(
          create: (context) => GoalBloc(aiService, prefs)..add(LoadGoals()),
        ),
        BlocProvider<FocusBloc>(
          create: (context) => FocusBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Last-Minute Life Saver',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0C0C12),
          primaryColor: const Color(0xFF8A2BE2),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8A2BE2),
            secondary: Color(0xFF00E5FF),
            surface: Color(0xFF161622),
            error: Color(0xFFFF5722),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1B1B2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0x1FFFFFFF), width: 1),
            ),
          ),
          textTheme: const TextTheme(
            headlineMedium: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5F5F7),
            ),
            titleLarge: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF5F5F7),
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
        home: DashboardScreen(aiService: aiService, prefs: prefs),
      ),
    );
  }
}
