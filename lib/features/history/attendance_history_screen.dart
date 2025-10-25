
// Placeholder for the history screen
import 'package:flutter/material.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final String classId;
  const AttendanceHistoryScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Attendance History'),
      ),
      body: const Center(
        child: Text('Past session records will be listed here.'),
      ),
    );
  }
}