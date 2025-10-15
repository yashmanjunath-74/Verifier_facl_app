import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';


final _studentsStreamProvider =
    StreamProvider.family<List<Student>, String>((ref, classId) {
  final db = ref.watch(databaseProvider);
  return db.studentDao.watchStudentsByClassId(classId);
});

class StudentRosterScreen extends ConsumerWidget {
  final String classId;
  const StudentRosterScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsStream = ref.watch(_studentsStreamProvider(classId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Roster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add Student via QR',
            onPressed: () => context.go('/scan/$classId'),
          ),
        ],
      ),
      body: studentsStream.when(
        data: (students) {
          if (students.isEmpty) {
            return const Center(
              child: Text("No students have been enrolled yet. Tap the '+' button to add one."),
            );
          }
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return ListTile(
                title: Text(student.name),
                subtitle: Text(student.studentId),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final faculty = ref.read(authNotifierProvider).value;
          if (faculty == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Not logged in.')),
            );
            return;
          }

          final p2pManager = ref.read(p2pManagerProvider);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final router = GoRouter.of(context);

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            await p2pManager.startSession(classId, faculty.username);
            final sessionId = p2pManager.currentSessionId;
            if (sessionId != null) {
              router.pop(); // Dismiss the loading dialog
              router.go('/session/$classId/$sessionId');
            }
          } catch (e) {
            router.pop(); // Dismiss the loading dialog
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Failed to start session: $e')),
            );
          }
        },
        label: const Text('Start Session'),
        icon: const Icon(Icons.timer_outlined),
      ),
    );
  }
}