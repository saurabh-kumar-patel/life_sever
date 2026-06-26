import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/ai_service.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';
import '../blocs/task/task_state.dart';
import '../blocs/focus/focus_bloc.dart';
import '../blocs/focus/focus_event.dart';

class AiChatSheet extends StatefulWidget {
  final AiService aiService;

  const AiChatSheet({super.key, required this.aiService});

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': "Hi! I'm your AI Proactive Companion. You can type or tap a command below to speak with me."
    }
  ];

  bool _isListening = false;
  String _listeningStatus = "Listening...";
  List<double> _waveValues = List.filled(15, 5.0);
  Timer? _waveTimer;

  final List<String> _suggestions = [
    "What should I do next?",
    "Schedule my tasks",
    "Add critical task Physics Report due today",
    "Focus on top task",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _waveTimer?.cancel();
    super.dispose();
  }

  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _waveValues = List.generate(15, (index) => 5.0 + (index % 3 + 1) * (2.0 + (5.0 * (timer.tick % 4))));
        });
      }
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
  }

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query});
    });
    _scrollToBottom();

    // AI thinking transition
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      
      final result = await widget.aiService.interpretVoiceCommand(query);
      final reply = result['reply'] as String;
      final action = result['action'] as String;

      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
      });
      _scrollToBottom();

      // Dispatch actions to Blocs based on AI analysis
      _handleAiAction(action, result);
    });
  }

  void _handleAiAction(String action, Map<String, dynamic> result) {
    final taskBloc = context.read<TaskBloc>();

    if (action == 'schedule') {
      taskBloc.add(AutoScheduleTasks());
    } else if (action == 'add_task') {
      taskBloc.add(AddTask(
        title: result['title'] as String,
        description: "Added via AI voice assistant.",
        deadline: result['deadline'] as DateTime,
        durationMinutes: result['duration'] as int,
        complexity: result['complexity'] as String,
        energyRequired: result['energy'] as String,
      ));
    } else if (action == 'focus_top') {
      final taskState = taskBloc.state;
      if (taskState is TasksLoaded && taskState.tasks.isNotEmpty) {
        final uncompleted = taskState.tasks.where((t) => !t.isCompleted).toList();
        if (uncompleted.isNotEmpty) {
          uncompleted.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
          final top = uncompleted.first;
          context.read<FocusBloc>().add(StartFocus(task: top, durationMinutes: 25));
          Navigator.pop(context, true); // Dismiss and flag focus transition
        }
      }
    } else if (action == 'recommend_next') {
      // Prompt option to start Pomodoro
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': "Would you like me to start the Pomodoro timer? (Tap 'Focus on top task' to start)"
        });
      });
      _scrollToBottom();
    }
  }

  void _simulateSpeech(String speechText) {
    setState(() {
      _isListening = true;
      _listeningStatus = "Listening...";
    });
    _startWaveAnimation();

    // Wait 2.5 seconds to simulate transcription
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() {
        _listeningStatus = "Processing speech...";
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isListening = false;
        });
        _stopWaveAnimation();
        _sendMessage(speechText);
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF131320),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            // Top grab handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI CO-PILOT ASSISTANT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x1FFFFFFF)),

            // Chat area
            Expanded(
              child: _isListening
                  ? _buildVoiceSimulationView()
                  : _buildMessagesView(),
            ),

            // Text input / Quick suggestions
            if (!_isListening) ...[
              // Suggestions list
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        backgroundColor: const Color(0xFF1C1C30),
                        side: const BorderSide(color: Color(0x13FFFFFF)),
                        label: Text(
                          _suggestions[index],
                          style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12),
                        ),
                        onPressed: () => _simulateSpeech(_suggestions[index]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              
              // Input bar
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (val) {
                          _sendMessage(val);
                          _controller.clear();
                        },
                        decoration: InputDecoration(
                          hintText: 'Ask AI or type command...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                          fillColor: const Color(0xFF1B1B2E),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.mic, color: Color(0xFF8A2BE2)),
                            onPressed: () => _simulateSpeech("What should I do next?"),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF8A2BE2),
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: () {
                          _sendMessage(_controller.text);
                          _controller.clear();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF8A2BE2) : const Color(0xFF1E1E32),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: const Color(0x0CFFFFFF), width: 1),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Text(
              msg['text']!,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.grey[200],
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceSimulationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulse voice icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF8A2BE2).withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: const Icon(
              Icons.mic,
              color: Color(0xFF00E5FF),
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          
          // Transcription indicator status
          Text(
            _listeningStatus,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sound wave bars
          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _waveValues.map((heightValue) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 3.5,
                  height: heightValue,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A2BE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "AI is listening to your vocal command...",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
