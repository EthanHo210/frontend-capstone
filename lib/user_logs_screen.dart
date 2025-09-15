import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';

class UserLogsScreen extends StatefulWidget {
  /// If true, renders content-only (no Scaffold/AppBar) for embedding inside MainDashboard.
  /// Use false to show as a standalone route.
  final bool embedded;

  const UserLogsScreen({super.key, this.embedded = false});

  @override
  State<UserLogsScreen> createState() => _UserLogsScreenState();
}

class _UserLogsScreenState extends State<UserLogsScreen> {
  final MockDatabase db = MockDatabase();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = db.currentLoggedInUser ?? '';
    final isTeacher = db.isTeacher(currentUser);
    final allUsers = db
        .getAllUsers()
        .where((user) => user['username'] != 'admin')
        .toList();

    // Filtering logic (unchanged)
    final filteredUsers = allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final q = searchQuery.toLowerCase();
      final matchesSearch = username.contains(q) || email.contains(q);
      if (!matchesSearch) return false;

      final role = user['role'];
      if (isTeacher && role == 'teacher') return false; // teachers don't see other teachers
      if (!isTeacher &&
          role != 'teacher' &&
          role != 'user' &&
          role != 'officer') {
        return false; // hide admins for non-teachers
      }
      return true;
    }).toList()
      ..sort((a, b) =>
          a['username'].toString().compareTo(b['username'].toString()));

    // Group by role
    final Map<String, List<Map<String, dynamic>>> categorized = {
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
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color
        ?? (isDark ? Colors.white70 : Colors.grey[700]!);
    final searchFill = isDark ? Colors.grey[800] : Colors.blue[50];
    final cardFill = isDark ? Theme.of(context).cardColor : Colors.blue[50];

    // Build just the content so we can reuse it in embedded/standalone modes
    final Widget content = SafeArea(
      child: Column(
        children: [
          // In-content back button ONLY when standalone (embedded parent already shows a header)
          if (!widget.embedded)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            ),

          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor: searchFill,
                prefixIcon: Icon(Icons.search,
                    color: isDark ? Colors.white70 : Colors.black54),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          const SizedBox(height: 6),

          // Body list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!isTeacher && categorized['Teachers']!.isNotEmpty)
                  _buildCategory('Teachers', categorized['Teachers']!,
                      isTeacher, primaryText, secondaryText, cardFill),
                if (categorized['Officers']!.isNotEmpty)
                  _buildCategory('Officers', categorized['Officers']!,
                      isTeacher, primaryText, secondaryText, cardFill),
                if (categorized['Students']!.isNotEmpty)
                  _buildCategory('Students', categorized['Students']!,
                      isTeacher, primaryText, secondaryText, cardFill),
              ],
            ),
          ),
        ],
      ),
    );

    // Embedded: return content only (no Scaffold)
    if (widget.embedded) return content;

    // Standalone: wrap in Scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: content,
    );
  }

  Widget _buildCategory(
    String label,
    List<Map<String, dynamic>> users,
    bool isTeacher,
    Color primaryText,
    Color secondaryText,
    Color? cardFill,
  ) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryText)),
        const SizedBox(height: 8),
        ...users.map((user) =>
            _buildUserCard(user, isTeacher, primaryText, secondaryText, cardFill)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic> user,
    bool isTeacher,
    Color primaryText,
    Color secondaryText,
    Color? cardFill,
  ) {
    final username = user['username']?.toString() ?? '';
    final fullName = user['fullName']?.toString() ?? username;
    final email = user['email']?.toString() ?? '';

    // IMPORTANT: project info is stored keyed by EMAIL in your app
    final projectInfo = db.getProjectInfoForUser(email);

    // Using the new keys you set elsewhere: name/status/completion
    final projName = projectInfo?['name'] ?? 'N/A';
    final projStatus = projectInfo?['status'] ?? 'N/A';
    final completion = projectInfo?['completion'] ?? '0%';

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
                  Text(fullName,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryText)),
                  const SizedBox(height: 8),
                  Text('Username: $username',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Email: $email',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Project: $projName',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Status: $projStatus',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Completion: $completion',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Assigned task: (Coming soon)',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Comment: (Coming soon)',
                      style: GoogleFonts.poppins(color: secondaryText)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryText)),
                  const SizedBox(height: 8),
                  Text('Username: $username',
                      style: GoogleFonts.poppins(color: secondaryText)),
                  Text('Email: $email',
                      style: GoogleFonts.poppins(color: secondaryText)),
                ],
              ),
      ),
    );
  }
}
