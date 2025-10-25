
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verifier_facl/features/attendance_session/live_session_screen.dart';

class StartSessionScreen extends ConsumerWidget {
  final String classId;
  const StartSessionScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop(),),
        title: const Text('Start Attendance Session'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LiveSessionScreen(
                  classId: classId,
                  sessionId: sessionId,
                ),
              ),
            );
          },
          child: const Text('Start Session'),
        ),
      ),
    );
  }
}
