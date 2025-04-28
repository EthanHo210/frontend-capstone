import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart'; // Make sure you have access to your MockDatabase

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final MockDatabase _db = MockDatabase();

  void _deleteUser(String username) {
    setState(() {
      _db.deleteUser(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = _db.getAllUsers();

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins(color: Colors.teal[800], fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal[800]),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(user['username']!, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: Text(user['email']!, style: GoogleFonts.poppins()),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteUser(user['username']!),
              ),
            ),
          );
        },
      ),
    );
  }
}