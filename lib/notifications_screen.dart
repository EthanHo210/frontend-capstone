import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// if you use provider; otherwise pass store manually
import 'data/notification_store.dart';
import 'mock_database.dart';

class NotificationsScreen extends StatelessWidget {
  final NotificationStore store;
  final MockDatabase db;
  const NotificationsScreen({super.key, required this.store, required this.db});

  @override
  Widget build(BuildContext context) {
    final username = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ?? '';
    final items = store.forUser(username);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => store.markAllRead(username),
            child: Text('Mark all read', style: GoogleFonts.poppins(color: Colors.white)),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final n = items[i];
          return ListTile(
            leading: Icon(
              n.type == 'task_assigned' ? Icons.assignment_turned_in_rounded
                : n.type == 'proof_uploaded' ? Icons.image_outlined
                : Icons.folder_open_rounded,
              color: n.read ? Colors.grey : Colors.blueAccent,
            ),
            title: Text(n.title, style: GoogleFonts.poppins(
              fontWeight: n.read ? FontWeight.w400 : FontWeight.w600,
            )),
            subtitle: Text(n.body, style: GoogleFonts.poppins()),
            trailing: Text(
              _timeAgo(n.createdAt),
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              store.markRead(username, n.id);
              // Optionally navigate to project/task screen using n.payload
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
    }
}
