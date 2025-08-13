import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

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
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final matchesSearch = username.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final role = user['role'];
      if (isTeacher && role == 'teacher') return false;
      if (!isTeacher && role != 'teacher' && role != 'user' && role != 'officer') return false;

      return true;
    }).toList();

    filteredUsers.sort((a, b) => a['username'].toString().compareTo(b['username'].toString()));

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

    // Theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = Theme.of(context).textTheme.titleLarge?.color
        ?? Theme.of(context).textTheme.bodyLarge?.color
        ?? (isDark ? Colors.white : Colors.black);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.white70 : Colors.grey[700]!);
    final searchFill = isDark ? Colors.grey[800] : Colors.blue[50];
    final cardFill = isDark ? Theme.of(context).cardColor : Colors.blue[50];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: primaryText),
        title: Text(
          isTeacher ? 'Member Logs' : 'User Directory',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: primaryText,
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
                fillColor: searchFill,
                prefixIcon: Icon(Icons.search, color: secondaryText),
                hintStyle: GoogleFonts.poppins(color: secondaryText),
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
            _buildCategory('Teachers', categorized['Teachers']!, isTeacher, primaryText, secondaryText, cardFill),
          if (categorized['Officers']!.isNotEmpty)
            _buildCategory('Officers', categorized['Officers']!, isTeacher, primaryText, secondaryText, cardFill),
          if (categorized['Students']!.isNotEmpty)
            _buildCategory('Students', categorized['Students']!, isTeacher, primaryText, secondaryText, cardFill),
        ],
      ),
    );
  }

  Widget _buildCategory(String label, List<Map<String, dynamic>> users, bool isTeacher,
      Color primaryText, Color secondaryText, Color? cardFill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: primaryText)),
        const SizedBox(height: 8),
        ...users.map((user) => _buildUserCard(user, isTeacher, primaryText, secondaryText, cardFill)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isTeacher, Color primaryText, Color secondaryText, Color? cardFill) {
    final username = user['username']?.toString() ?? '';
    final fullName = user['fullName']?.toString() ?? username;
    final projectInfo = db.getProjectInfoForUser(username);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardFill,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isTeacher
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryText)),
                  const SizedBox(height: 8),
                  Text('Username: $username', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Email: ${user['email']}', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Project team: ${projectInfo?['project'] ?? 'N/A'}', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Project status: ${projectInfo?['rank'] ?? 'N/A'}', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Assigned task: (Coming soon)', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Contribution rate: ${projectInfo?['contribution'] ?? '0%'}', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Comment: (Coming soon)', style: GoogleFonts.poppins(color: secondaryText)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryText)),
                  const SizedBox(height: 8),
                  Text('Username: $username', style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Email: ${user['email']}', style: GoogleFonts.poppins(color: secondaryText)),
                ],
              ),
      ),
    );
  }
}
