import 'dart:async'; // Needed for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verifier_facl/core/providers/services_provider.dart'; // Ensure correct path
import 'package:verifier_facl/core/services/p2p/p2p_manager.dart'; // Ensure correct path
import 'package:verifier_facl/features/class_management/student_roster_screen.dart'; // Needed for student count

// Provider to watch the stream of attendance updates from the P2PManager
final attendanceUpdatesProvider = StreamProvider.autoDispose<AttendanceUpdate>((
  ref,
) {
  final p2pManager = ref.watch(p2pManagerProvider);
  return p2pManager.attendanceStream;
});

class LiveSessionScreen extends ConsumerStatefulWidget {
  final String classId;
  final String sessionId; // Passed via router
  const LiveSessionScreen({
    super.key,
    required this.classId,
    required this.sessionId,
  });

  @override
  ConsumerState<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends ConsumerState<LiveSessionScreen> {
  // Store the events locally to build the activity feed
  final List<AttendanceUpdate> _events = [];
  // Keep track of the stream subscription to cancel it later
  StreamSubscription? _attendanceSubscription;

  @override
  void initState() {
    super.initState();
    // Start listening to attendance updates as soon as the screen is built
    _listenToUpdates();
  }

  void _listenToUpdates() {
    // Read the P2PManager instance
    final p2pManager = ref.read(p2pManagerProvider);
    // Subscribe to its stream
    _attendanceSubscription = p2pManager.attendanceStream.listen((update) {
      // Check if the widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          // Add event to the beginning of the list if it's new
          // Check based on studentId and type to avoid duplicates if stream fires rapidly
          if (!_events.any(
            (e) => e.studentId == update.studentId && e.type == update.type,
          )) {
            _events.insert(
              0,
              update,
            ); // Add to top for reverse chronological order
          }
          // Handle session ended event
          if (update.type == AttendanceUpdateType.sessionEnded) {
            // Optionally show a final message
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(update.message)));
            // Maybe navigate back after a delay?
            // Future.delayed(Duration(seconds: 2), () => context.go('/classes'));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Cancel the stream subscription to prevent memory leaks
    // and `setState` errors after the screen is destroyed.
    _attendanceSubscription?.cancel();
    super.dispose();
  }

  // --- UI Build Method ---
  @override
  Widget build(BuildContext context) {
    // Get the total number of students for stats (using the provider from StudentRosterScreen)
    // Watch it so it updates if the roster changes (though unlikely during a session)
    final totalStudentsAsyncValue = ref.watch(
      studentStreamProvider(widget.classId),
    );
    final totalStudents = totalStudentsAsyncValue.value?.length ?? 0;

    // Calculate the number of successfully verified students
    final presentCount = _events
        .where((e) => e.type == AttendanceUpdateType.studentVerified)
        .length;

    return PopScope(
      // Prevent accidental back navigation during session
      canPop: false, // Don't allow back button press
      onPopInvoked: (didPop) {
        if (!didPop) {
          // If pop was prevented, show confirmation to end session
          _showEndSessionDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Live Session (${widget.sessionId.substring(0, 6)}...)',
          ), // Show partial session ID
          // Prevent back navigation using automaticallyImplyLeading
          automaticallyImplyLeading: false,
          actions: [
            // Button to manually end the session
            TextButton(
              onPressed: _showEndSessionDialog, // Show confirmation dialog
              child: const Text('END'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header showing live statistics
            _buildStatsHeader(presentCount, totalStudents),
            const Divider(height: 1),
            // Activity Feed showing verification events
            Expanded(
              child: _events.isEmpty
                  ? const Center(
                      // Show message while waiting for first student
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 20),
                          Text('Waiting for students to connect...'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      // Display events
                      // reverse: true, // Display newest events at the top (handled by inserting at 0)
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        // Build a tile for each event
                        return _buildEventTile(event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  // --- End UI Build Method ---

  // --- Helper Widgets ---
  Widget _buildStatsHeader(int present, int total) {
    // Calculate progress for the LinearProgressIndicator
    double progress = total > 0 ? present / total : 0.0;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "LIVE" indicator
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              // Present count / Total students
              Text(
                'PRESENT: $present / $total',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar visual
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  // Builds a ListTile for each event in the activity feed
  Widget _buildEventTile(AttendanceUpdate event) {
    IconData icon;
    Color color;
    String title = event.studentName ?? event.studentId ?? "Unknown Student";

    // Determine icon and color based on event type
    switch (event.type) {
      case AttendanceUpdateType.studentVerified:
        icon = Icons.check_circle_outline;
        color = Colors.green.shade700;
        break;
      case AttendanceUpdateType.studentFailed:
        icon = Icons.error_outline;
        color = Colors.red.shade700;
        break;
      case AttendanceUpdateType.sessionStarted:
        icon = Icons.play_circle_outline;
        color = Colors.blue.shade700;
        title = "Session"; // Don't show student name for session start
        break;
      case AttendanceUpdateType.sessionEnded:
        icon = Icons.stop_circle_outlined;
        color = Colors.grey.shade700;
        title = "Session"; // Don't show student name for session end
        break;
      default: // Other types like error, connected (if used)
        icon = Icons.info_outline;
        color = Colors.orange.shade700;
    }

    // Don't show tiles for non-student specific events like start/end in the main feed
    // if (event.type == AttendanceUpdateType.sessionStarted || event.type == AttendanceUpdateType.sessionEnded) {
    //    return const SizedBox.shrink(); // Hide session start/end messages from list
    // }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(event.message), // Display the message from the P2PManager
      trailing: Text(
        TimeOfDay.fromDateTime(DateTime.now()).format(context),
      ), // Show time of event
      dense: true,
    );
  }
  // --- End Helper Widgets ---

  // --- Dialog Logic ---
  // Shows the confirmation dialog before ending the session
  void _showEndSessionDialog() {
    // Check if session already ended to avoid showing dialog unnecessarily
    final p2pManager = ref.read(p2pManagerProvider);
    if (p2pManager.currentSessionId == null) {
      // If session already ended, just go back
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/classes'); // Fallback if cannot pop
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an action
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'This will mark all remaining students as absent and disconnect everyone. Are you sure?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            // Close the dialog
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
            onPressed: () {
              // Call the stopSession method in the P2P Manager
              p2pManager.stopSession();
              // Close the dialog
              Navigator.of(dialogContext).pop();
              // Navigate back to the class list screen
              // Use context.go for router navigation
              context.go('/classes');
            },
          ),
        ],
      ),
    );
  }
  // --- End Dialog Logic ---
}
