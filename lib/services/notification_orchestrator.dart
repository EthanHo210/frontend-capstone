import 'dart:async';
import 'dart:math';
import '../data/notification_store.dart';
import '../models/app_notification.dart';
import '../events/app_events.dart';
import 'notification_service.dart';
import '../mock_database.dart'; // to check user’s notif setting (we’ll add a flag)

class NotificationOrchestrator {
  NotificationOrchestrator(this._store, this._db);
  final NotificationStore _store;
  final MockDatabase _db; // your existing mock DB, we’ll add a toggle flag

  StreamSubscription? _sub;

  void start() {
    _sub ??= AppEventBus.instance.stream.listen(_handle);
  }

  void dispose() { _sub?.cancel(); _sub = null; }

  Future<void> _handle(AppEvent e) async {
    final rnd = Random();

    if (e is ProjectCreated) {
      for (final u in e.members) {
        _store.add(u, AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1<<32)}',
          title: 'New project added',
          body: '${e.projectName} (${e.courseName}) has been created.',
          createdAt: DateTime.now(),
          type: 'project_created',
          payload: e.projectName,
        ));
        if (_db.isNotificationsEnabled(u)) {
          await NotificationService.instance.showLocal(
            id: rnd.nextInt(1<<31),
            title: 'New project',
            body: '${e.projectName} was created',
            payload: e.projectName,
          );
        }
      }
    }

    if (e is TaskAssigned) {
      _store.add(e.assignee, AppNotification(
        id: 'n_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1<<32)}',
        title: 'Task assigned',
        body: '${e.taskName} in ${e.projectName}',
        createdAt: DateTime.now(),
        type: 'task_assigned',
        payload: e.projectName,
      ));
      if (_db.isNotificationsEnabled(e.assignee)) {
        await NotificationService.instance.showLocal(
          id: rnd.nextInt(1<<31),
          title: 'Task assigned',
          body: '${e.taskName} in ${e.projectName}',
          payload: e.projectName,
        );
      }
    }

    if (e is ProofUploaded) {
      for (final r in e.reviewers) {
        _store.add(r, AppNotification(
          id: 'n_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1<<32)}',
          title: 'Proof uploaded',
          body: '${e.uploader} submitted proof for ${e.subtaskName} (${e.projectName})',
          createdAt: DateTime.now(),
          type: 'proof_uploaded',
          payload: e.projectName,
        ));
        if (_db.isNotificationsEnabled(r)) {
          await NotificationService.instance.showLocal(
            id: rnd.nextInt(1<<31),
            title: 'New proof submitted',
            body: '${e.subtaskName} • ${e.projectName}',
            payload: e.projectName,
          );
        }
      }
    }
  }
}
