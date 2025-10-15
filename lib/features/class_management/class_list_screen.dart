import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:verifier_facl/common_widgets/custom_card.dart';
import 'package:verifier_facl/core/models/class_group.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';

final _classesStreamProvider = StreamProvider<List<ClassGroup>>((ref) {
  final db = ref.watch(databaseProvider);
  final faculty = ref.watch(currentFacultyProvider);
  if (faculty != null) {
    return db.classGroupDao.watchAllClassesByFacultyId(faculty.facultyId);
  }
  return Stream.value([]);
});

class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesStream = ref.watch(_classesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: classesStream.when(
        data: (classes) {
          if (classes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No classes found.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Class'),
                    onPressed: () => context.go('/create-class'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classGroup = classes[index];
              return CustomCard(
                onTap: () => context.go('/roster/${classGroup.classId}'),
                child: ListTile(
                  title: Text(classGroup.className),
                  subtitle: Text(classGroup.courseCode),
                  trailing: Text(
                    DateFormat.yMMMd().format(classGroup.createdAt),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create-class'),
        label: const Text('New Class'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
