import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'mock_database.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  bool isAdmin = false;

  Map<String, String>? _projectInfo;

  @override
  void initState() {
    super.initState();
    _loadProjectInfo();
  }

  void _loadProjectInfo() {
    final user = MockDatabase().currentLoggedInUser;
    _projectInfo = MockDatabase().getProjectInfoForUser(user ?? '');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/start_new_project');
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(isAdmin: isAdmin),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    final userEmail = args?['email'] ?? 'Guest';
    final username = args?['username'] ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    isAdmin = (args?['isAdmin'] ?? 'false') == 'true';

    final projectName = _projectInfo?['project'] ?? 'No project';
    final contribution = _projectInfo?['contribution'] ?? '0%';
    final rank = _projectInfo?['rank'] ?? 'Unranked';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Together!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        actions: [
          if (isLoggedIn)
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal[100],
                  child: const Icon(Icons.person, size: 18, color: Colors.teal),
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: GoogleFonts.poppins(
                    color: Colors.teal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LAST UPDATED',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Project : $projectName\nContribution Rate : $contribution\nRank : $rank',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.teal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  tooltip: 'Edit Project Info',
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/update_project');
                    setState(() => _loadProjectInfo()); // Reload project info after editing
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Your project',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFFEFBEA),
        iconSize: 32,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Start New',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
