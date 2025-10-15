
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:verifier_facl/common_widgets/custom_button.dart';
import 'package:verifier_facl/core/models/class_group.dart';
import 'package:verifier_facl/core/providers/auth_provider.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';

class CreateClassScreen extends ConsumerStatefulWidget {
  const CreateClassScreen({super.key});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createClass() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final faculty = ref.read(currentFacultyProvider);
      if (faculty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Not logged in.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final newClass = ClassGroup(
        classId: const Uuid().v4(),
        className: _classNameController.text,
        courseCode: _courseCodeController.text,
        facultyId: faculty.facultyId,
        createdAt: DateTime.now(),
      );

      try {
        await ref.read(databaseProvider).classGroupDao.insertClass(newClass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class created successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create class: $e')),
          );
        }
      } finally {
        if(mounted) {
           setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Class'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g., Software Engineering',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a class name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g., CS301',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a course code' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Create Class',
                onPressed: _createClass,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}