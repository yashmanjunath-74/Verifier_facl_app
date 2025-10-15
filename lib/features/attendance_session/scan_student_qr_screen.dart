import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';

class ScanStudentQrScreen extends ConsumerWidget {
  final String classId;
  const ScanStudentQrScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Student QR Code')),
      body: MobileScanner(
        onDetect: (capture) async {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? qrData = barcodes.first.rawValue;
            if (qrData != null) {
              final cryptoService = ref.read(cryptoServiceProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                final studentData = cryptoService.parseQrData(qrData);

                final student = Student(
                  studentId: studentData['studentId']!,
                  name: studentData['name']!,
                  publicKey: studentData['publicKey']!,
                  createdAt: DateTime.now(),
                  enrolledAt: DateTime.now(),
                  classId: classId,
                );

                final db = ref.read(databaseProvider);
                await db.studentDao.insertStudent(student);

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Student ${student.name} enrolled.')),
                );
                navigator.pop();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Invalid QR Code.')),
                );
              }
            }
          }
        },
      ),
    );
  }
}