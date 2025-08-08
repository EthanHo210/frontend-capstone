import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class UserLogsScreen extends StatefulWidget {
  const UserLogsScreen({super.key});

  @override
  State<UserLogsScreen> createState() => _UserLogsScreenState();
}

class _UserLogsScreenState extends State<UserLogsScreen> {
  final MockDatabase db = MockDatabase();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = db.currentLoggedInUser ?? '';
    final isTeacher = db.isTeacher(currentUser);
    final allUsers = db.getAllUsers().where((user) => user['username'] != 'admin').toList();

    final filteredUsers = allUsers.where((user) {
      final username = user['username']!.toLowerCase();
      final email = user['email']!.toLowerCase();
      final matchesSearch = username.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final role = user['role'];
      if (isTeacher && role == 'teacher') return false;
      if (!isTeacher && role != 'teacher' && role != 'user' && role != 'officer') return false;

      return true;
    }).toList();

    filteredUsers.sort((a, b) => a['username'].compareTo(b['username']));

    Map<String, List<Map<String, dynamic>>> categorized = {
      'Teachers': [],
      'Officers': [],
      'Students': [],
      
    };

    for (var user in filteredUsers) {
      if (user['role'] == 'teacher') {
        categorized['Teachers']!.add(user);
      } else if (user['role'] == 'officer') {
        categorized['Officers']!.add(user);
      } else {
        categorized['Students']!.add(user);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          isTeacher ? 'Member Logs' : 'User Directory',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                filled: true,
                fillColor: Colors.blue[50],
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isTeacher && categorized['Teachers']!.isNotEmpty)
            _buildCategory('Teachers', categorized['Teachers']!, isTeacher),
          if (categorized['Officers']!.isNotEmpty)
            _buildCategory('Officers', categorized['Officers']!, isTeacher),
          if (categorized['Students']!.isNotEmpty)
            _buildCategory('Students', categorized['Students']!, isTeacher),
          
        ],
      ),
    );
  }

  Widget _buildCategory(String label, List<Map<String, dynamic>> users, bool isTeacher) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blueText)),
        const SizedBox(height: 8),
        ...users.map((user) => _buildUserCard(user, isTeacher)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isTeacher) {
    final username = user['username'];
    final fullName = user['fullName'];
    final projectInfo = db.getProjectInfoForUser(username);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isTeacher
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blueText)),
                  /*const SizedBox(height: 4),
                  Text('ID: ${user['id'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),*/

                  const SizedBox(height: 8),
                  Text('Username: ${user['username']}', style: GoogleFonts.poppins()),
                  Text('Email: ${user['email']}', style: GoogleFonts.poppins()),
                  Text('Project team: ${projectInfo?['project'] ?? 'N/A'}', style: GoogleFonts.poppins()),
                  Text('Project status: ${projectInfo?['rank'] ?? 'N/A'}', style: GoogleFonts.poppins()),
                  Text('Assigned task: (Coming soon)', style: GoogleFonts.poppins()),
                  Text('Contribution rate: ${projectInfo?['contribution'] ?? '0%'}', style: GoogleFonts.poppins()),
                  Text('Comment: (Coming soon)', style: GoogleFonts.poppins()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blueText)),
                  /*const SizedBox(height: 4),
                  Text('ID: ${user['id'] ?? 'N/A'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),*/

                  const SizedBox(height: 8),
                  Text('Username: ${user['username']}', style: GoogleFonts.poppins()),
                  Text('Email: ${user['email']}', style: GoogleFonts.poppins()),
                ],
              ),
      ),
    );
  }
}
