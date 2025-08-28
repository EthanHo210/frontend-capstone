import 'dart:async';
import '../mock_database.dart';

/// Periodically checks project deadlines and notifies members when a project
/// enters the "crisis window" (deadline is near).
class DeadlineNotifier {
  DeadlineNotifier({
    required this.db,
    this.crisisDays = 7,                          // how many days before due date to alert
    this.checkEvery = const Duration(hours: 6),   // how often to scan (shorten for testing)
  });

  final MockDatabase db;
  final int crisisDays;
  final Duration checkEvery;

  Timer? _timer;

  /// Keep track of projects we've already alerted for the current crisis window,
  /// so we don't spam the same message repeatedly.
  final Set<String> _alreadyNotified = <String>{};

  void start() {
    _tick(); // run immediately on start
    _timer = Timer.periodic(checkEvery, (_) => _tick());
  }

  void stop() => _timer?.cancel();

  void _tick() {
    final now = DateTime.now();

    for (final p in db.getAllProjects()) {
      final projName = (p['name'] ?? '').toString();
      if (projName.isEmpty) continue;

      final projKey = (p['id'] ?? projName).toString(); // ← use id when available

      final deadlineStr = (p['deadline'] ?? '').toString();
      final deadline = DateTime.tryParse(deadlineStr);
      if (deadline == null) continue;

      final status = (p['status'] ?? '').toString().toLowerCase();
      final isCompleted = status == 'completed';
      if (isCompleted) {
        _alreadyNotified.remove(projKey);
        continue;
      }

      final remaining = deadline.difference(now);
      final daysLeft = remaining.inDays;

      if (daysLeft > crisisDays || remaining.isNegative) {
        _alreadyNotified.remove(projKey);
        continue;
      }

      if (_alreadyNotified.contains(projKey)) continue;

      final remainingText = _format(remaining);
      _notifyProject(
        projName,
        title: 'Deadline approaching',
        body: '$projName is due in $remainingText. Please finish your tasks soon.',
      );

      _alreadyNotified.add(projKey);
    }
  }


  void _notifyProject(String projectName, {required String title, required String body}) {
    db.notifyProjectMembers(
      projectName,
      title: title,
      body: body,
      type: 'deadline',
    );
  }


  String _format(Duration d) {
    if (d.inDays >= 1) {
      final days = d.inDays;
      final hours = d.inHours % 24;
      return hours > 0 ? '$days days $hours hours' : '$days days';
    }
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final mins = d.inMinutes % 60;
      return mins > 0 ? '$hours hours $mins minutes' : '$hours hours';
    }
    final mins = d.inMinutes;
    return mins > 0 ? '$mins minutes' : 'less than a minute';
  }
}
