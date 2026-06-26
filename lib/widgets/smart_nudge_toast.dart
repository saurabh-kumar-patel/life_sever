import 'package:flutter/material.dart';
import '../models/task_model.dart';

class SmartNudgeToast extends StatelessWidget {
  final Task task;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const SmartNudgeToast({
    super.key,
    required this.task,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1F35), Color(0xFF12121E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFFF5722),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🚨 PROACTIVE NUDGE',
                  style: TextStyle(
                    color: Color(0xFFFF5722),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\'${task.title}\' is due soon!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Takes ~${task.durationMinutes}m. Start now to beat the clock.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'FOCUS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Ignore',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
