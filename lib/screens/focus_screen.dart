import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/task_model.dart';
import '../blocs/focus/focus_bloc.dart';
import '../blocs/focus/focus_event.dart';
import '../blocs/focus/focus_state.dart';
import '../blocs/task/task_bloc.dart';
import '../blocs/task/task_event.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  bool _lofiPlaying = false;
  int _tipIndex = 0;
  Timer? _tipTimer;
  final List<String> _focusTips = [
    "Put your phone in another room to avoid notification traps.",
    "Draft a single micro-task to work on next. Don't think of the whole project.",
    "Your brain takes ~20 minutes to re-focus after an interruption. Guard your attention!",
    "Take deep breaths if you feel overwhelmed by the deadline.",
    "Procrastination is an emotional regulation problem, not a time management one. Be kind to yourself."
  ];

  @override
  void initState() {
    super.initState();
    // Rotate tips every 20 seconds
    _tipTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (!mounted) return;
      setState(() {
        _tipIndex = (_tipIndex + 1) % _focusTips.length;
      });
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FocusBloc, FocusState>(
      listener: (context, state) {
        if (state is FocusFinished) {
          // Auto-mark task complete
          context.read<TaskBloc>().add(ToggleTaskComplete(state.task.id));
          _showFinishedDialog(state.task);
        }
      },
      builder: (context, state) {
        if (state is! FocusRunning) {
          return const Scaffold(
            body: Center(child: Text('No active focus session.')),
          );
        }

        final running = state;
        final progress = running.progress;
        final timeStr = _formatTime(running.secondsRemaining);

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              context.read<FocusBloc>().add(CancelFocus());
            }
          },
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF07070F), Color(0xFF0F0F23)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header / Exit
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hourglass_empty, color: Color(0xFFFF5722)),
                              SizedBox(width: 8),
                              Text(
                                'DEEP FOCUS SESSION',
                                style: TextStyle(
                                  color: Color(0xFFFF5722),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              context.read<FocusBloc>().add(CancelFocus());
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Timer circle with progress indicator
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glass backdrop card
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.02),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                          ),
                          // Outer glowing progress arc
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              color: const Color(0xFF8A2BE2),
                              backgroundColor: const Color(0x1F8A2BE2),
                            ),
                          ),
                          // Custom cyan glow ring for the ticking visual
                          SizedBox(
                            width: 254,
                            height: 254,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2,
                              color: const Color(0xFF00E5FF),
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          // Timer texts
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                running.isPaused ? 'TIMER PAUSED' : 'STAY FOCUSED',
                                style: TextStyle(
                                  color: running.isPaused ? const Color(0xFFFF5722) : const Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Current Task details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            running.task.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            running.task.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Lofi Audio toggle (simulated micro-interaction)
                    _buildLofiPlayerWidget(),

                    const SizedBox(height: 24),

                    // Tip Banner
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161629),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: Color(0xFF00E5FF), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI PRODUCTIVITY COACH',
                                  style: TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _focusTips[_tipIndex],
                                    key: ValueKey<int>(_tipIndex),
                                    style: TextStyle(
                                      color: Colors.grey[350],
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Timer Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Abort/Cancel
                          ElevatedButton(
                            onPressed: () {
                              context.read<FocusBloc>().add(CancelFocus());
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.red[400],
                              side: BorderSide(color: Colors.red[900]!, width: 1.5),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('ABORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),

                          // Play/Pause
                          FloatingActionButton.large(
                            onPressed: () {
                              if (running.isPaused) {
                                context.read<FocusBloc>().add(ResumeFocus());
                              } else {
                                context.read<FocusBloc>().add(PauseFocus());
                              }
                            },
                            backgroundColor: const Color(0xFF8A2BE2),
                            foregroundColor: Colors.white,
                            child: Icon(
                              running.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                              size: 38,
                            ),
                          ),

                          // Instant Complete
                          ElevatedButton(
                            onPressed: () {
                              context.read<FocusBloc>().add(CompleteFocus());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF0F0F23),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('COMPLETE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLofiPlayerWidget() {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x0CFFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _lofiPlaying ? Icons.music_off_rounded : Icons.music_note_rounded,
              color: const Color(0xFF00E5FF),
            ),
            onPressed: () {
              setState(() {
                _lofiPlaying = !_lofiPlaying;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lofiPlaying 
                  ? 'Playing Simulated Lo-Fi Focus Waves...' 
                  : 'Enable Focus Lo-Fi Background Beat',
              style: TextStyle(
                color: _lofiPlaying ? const Color(0xFF00E5FF) : Colors.grey[400],
                fontSize: 11,
                fontWeight: _lofiPlaying ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_lofiPlaying) ...[
            const SizedBox(width: 8),
            // Tiny simulated visualizer animation bars
            _buildMiniAudioBars(),
          ]
        ],
      ),
    );
  }

  Widget _buildMiniAudioBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 2.5,
          height: 12.0 - (index * 3),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  void _showFinishedDialog(Task task) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF00E5FF)),
            SizedBox(width: 10),
            Text('Congratulations!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'You completed the pomodoro session for "${task.title}"! This deadline has been successfully completed.',
          style: const TextStyle(color: Color(0xFF9E9E9E)),
        ),
        actions: [
          TextButton(
            child: const Text('Awesome!', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Exit Focus Screen
            },
          ),
        ],
      ),
    );
  }
}
