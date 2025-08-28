import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationStore extends ChangeNotifier {
  final Map<String, List<AppNotification>> _byUser = {}; // username -> list

  UnmodifiableListView<AppNotification> forUser(String username) {
    final list = _byUser[username] ?? [];
    list.sort((a,b) => b.createdAt.compareTo(a.createdAt));
    return UnmodifiableListView(list);
  }

  int unreadCount(String username) =>
      (_byUser[username] ?? []).where((n) => !n.read).length;

  void add(String username, AppNotification n) {
    final list = _byUser.putIfAbsent(username, () => []);
    list.add(n);
    notifyListeners();
  }

  void markAllRead(String username) {
    for (final n in (_byUser[username] ?? [])) { n.read = true; }
    notifyListeners();
  }

  void markRead(String username, String id) {
    final n = (_byUser[username] ?? []).firstWhere((x) => x.id == id, orElse: () => AppNotification(id:'',title:'',body:'',createdAt:DateTime.now(),type:'noop'));
    if (n.id.isNotEmpty) { n.read = true; notifyListeners(); }
  }
}
