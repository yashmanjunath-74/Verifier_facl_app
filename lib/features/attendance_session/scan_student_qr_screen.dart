import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';

class ScanStudentQrScreen extends ConsumerStatefulWidget {
  final String classId;
  const ScanStudentQrScreen({super.key, required this.classId});

  @override
  ConsumerState<ScanStudentQrScreen> createState() =>
      _ScanStudentQrScreenState();
}

class _ScanStudentQrScreenState extends ConsumerState<ScanStudentQrScreen> {
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrData = barcodes.first.rawValue!;
      // Correctly read the cryptoService instance from the provider
      final cryptoService = ref.read(cryptoServiceProvider);
      final db = ref.read(databaseProvider);

      final studentData = cryptoService.parseStudentQR(qrData);

      if (studentData != null) {
        try {
          final newStudent = Student(
            studentId: studentData['studentId']!,
            name: studentData['name']!,
            classId: widget.classId,
            publicKey: studentData['publicKey']!,
            createdAt: DateTime.now(),
            enrolledAt: DateTime.now(),
          );

          await db.studentDao.insertStudent(newStudent);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully enrolled ${newStudent.name}'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving student: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid QR Code Format'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/roster/${widget.classId}'),
        ),
        title: const Text('Scan Student QR Code'),
      ),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
