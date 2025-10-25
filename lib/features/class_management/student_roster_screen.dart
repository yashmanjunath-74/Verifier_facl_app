import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifier_facl/common_widgets/custom_card.dart';
import 'package:verifier_facl/common_widgets/loading_overlay.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';

// A StreamProvider that takes a classId as an input (a "family")
// and watches the students for only that class. This ensures the UI is always up to date.
final studentStreamProvider = StreamProvider.family<List<Student>, String>((
  ref,
  classId,
) {
  final db = ref.watch(databaseProvider);
  return db.studentDao.watchStudentsByClassId(classId);
});

// A simple StateProvider to manage the loading state when starting a session.
final _isLoadingProvider = StateProvider<bool>((ref) => false);

class StudentRosterScreen extends ConsumerWidget {
  final String classId;
  const StudentRosterScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the stream provider, passing in the classId from the router.
    final studentsStream = ref.watch(studentStreamProvider(classId));
    // We also watch the loading state provider.
    final isLoading = ref.watch(_isLoadingProvider);

    // The LoadingOverlay will show a spinner on top of the screen when isLoading is true.
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go('/classes')),
          title: const Text('Student Roster'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add Student via QR',
              onPressed: () {
                // Navigate to the QR scanner screen for this specific class.
                context.go('/scan/$classId');
              },
            ),
          ],
        ),
        body: studentsStream.when(
          data: (students) {
            // Display a helpful message if no students are enrolled yet.
            if (students.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No students enrolled yet.',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Tap the '+' icon to scan a student's QR code.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            // If there are students, display them in a list.
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return CustomCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student.name.substring(0, 1)),
                    ),
                    title: Text(student.name),
                    subtitle: Text(student.studentId),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // Show the loading overlay while starting the session.
            ref.read(_isLoadingProvider.notifier).state = true;
            try {
              // Call the manager to start the P2P session.
              final p2pManager = ref.read(p2pManagerProvider);
              final sessionId = await p2pManager.startSession(classId);

              // If successful, navigate to the live session screen.
              if (context.mounted) {
                context.go('/session/$classId/$sessionId');
              }
            } catch (e) {
              // If there's an error (e.g., permissions denied), show it.
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to start session: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              // Always hide the loading overlay afterwards.
              if (context.mounted) {
                ref.read(_isLoadingProvider.notifier).state = false;
              }
            }
          },
          label: const Text('Start Session'),
          icon: const Icon(Icons.sensors),
        ),
      ),
    );
  }
}
