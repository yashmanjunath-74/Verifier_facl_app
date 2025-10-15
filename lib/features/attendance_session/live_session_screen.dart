import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifier_facl/core/models/student.dart';
import 'package:verifier_facl/core/providers/database_provider.dart';
import 'package:verifier_facl/core/providers/services_provider.dart';
import 'package:verifier_facl/core/services/p2p/p2p_manager.dart';

final _studentsStreamProvider =
    StreamProvider.family<List<Student>, String>((ref, classId) {
  final db = ref.watch(databaseProvider);
  return db.studentDao.watchStudentsByClassId(classId);
});

class LiveSessionScreen extends ConsumerStatefulWidget {
  final String classId;
  final String sessionId;
  const LiveSessionScreen(
      {super.key, required this.classId, required this.sessionId});

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  final List<AttendanceUpdate> _updates = [];
  int _presentCount = 0;

  @override
  void initState() {
    super.initState();
    ref.read(p2pManagerProvider).attendanceStream.listen((update) {
      setState(() {
        _updates.insert(0, update);
        if (update.type == AttendanceUpdateType.studentVerified) {
          _presentCount++;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsyncValue = ref.watch(_studentsStreamProvider(widget.classId));
    final totalStudents = studentsAsyncValue.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Session'),
        actions: [
          TextButton(
            onPressed: () => _showEndSessionDialog(),
            child: const Text('END SESSION'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLiveStats(totalStudents),
          _buildActivityFeed(),
        ],
      ),
    );
  }

  Widget _buildLiveStats(int totalStudents) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Present: $_presentCount / $totalStudents',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed() {
    if (_updates.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Listening for students...'),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: _updates.length,
        itemBuilder: (context, index) {
          final update = _updates[index];
          return ListTile(
            leading: _getIconForUpdate(update.type),
            title: Text(update.message),
            subtitle: update.studentName != null ? Text(update.studentName!) : null,
          );
        },
      ),
    );
  }

  Icon _getIconForUpdate(AttendanceUpdateType type) {
    switch (type) {
      case AttendanceUpdateType.studentVerified:
        return const Icon(Icons.check_circle, color: Colors.green);
      case AttendanceUpdateType.studentFailed:
        return const Icon(Icons.cancel, color: Colors.red);
      case AttendanceUpdateType.studentConnected:
        return const Icon(Icons.bluetooth_connected, color: Colors.blue);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Session?'),
          content: const Text(
              'Are you sure you want to end this session? All absent students will be marked accordingly.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('End Session'),
              onPressed: () async {
                await ref.read(p2pManagerProvider).stopSession();
                // Pop the dialog and then the screen
                // ignore: use_build_context_synchronously
                context.pop();
                // ignore: use_build_context_synchronously
                context.go('/roster/${widget.classId}');
              },
            ),
          ],
        );
      },
    );
  }
}