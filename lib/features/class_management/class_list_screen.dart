import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:verifier_facl/common_widgets/custom_card.dart';
import 'package:verifier_facl/core/models/class_group.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';

// This StreamProvider will automatically watch for changes in the classes table
final classesStreamProvider = StreamProvider<List<ClassGroup>>((ref) {
  final db = ref.watch(databaseProvider);
  final faculty = ref.watch(currentFacultyProvider);
  if (faculty != null) {
    return db.classGroupDao.watchAllClassesByFacultyId(faculty.facultyId);
  }
  return Stream.value([]); // Return an empty stream if not logged in
});

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesStream = ref.watch(classesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // This will log the user out and the router will automatically redirect to the login screen
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: classesStream.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No classes found.', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    "Tap '+' to create your first class.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          // Display the list of classes
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classGroup = classes[index];
              return CustomCard(
                onTap: () {
                  // NEW: Navigate to the student roster for this class
                  context.go('/roster/${classGroup.classId}');
                },
                child: ListTile(
                  title: Text(classGroup.className),
                  subtitle: Text(classGroup.courseCode),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // NEW: Navigate to the create class screen
          context.go('/create-class');
        },
        label: const Text('New Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
