import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import 'mock_database.dart';
import 'project_status_screen.dart';
import 'app_colors.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  Map<String, String>? _projectInfo;
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndProject();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserRoleAndProject();
  }

  void _loadUserRoleAndProject() {
    final db = MockDatabase();
    final user = db.currentLoggedInUser ?? '';
    setState(() {
      _projectInfo = db.getProjectInfoForUser(user);
      _userRole = db.getUserRole(user);
    });
  }

  void _onItemTapped(int index) {
    // For student users, Start New is hidden so indexes are shifted
    final isStudent = _userRole == 'user';
    final effectiveIndex = isStudent ? index + 1 : index;

    if (effectiveIndex == 0 && !isStudent) {
      Navigator.pushNamed(context, '/start_new_project');
    } else if (effectiveIndex == 1) {
      Navigator.pushNamed(context, '/courseTeams');
    } else if (effectiveIndex == 2) {
      return; // Tracking disabled
    } else if (effectiveIndex == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(isAdmin: _userRole == 'admin'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final userEmail = db.currentLoggedInUser ?? 'Guest';
    final username = db.getUsernameByEmail(userEmail) ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    final projectInfo = _projectInfo ?? {
      'project': 'No project',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };

    final projectName = projectInfo['project']!;
    final contribution = projectInfo['contribution']!;
    final deadline = projectInfo['deadline'] ?? 'N/A';
    final completion = int.tryParse(contribution.replaceAll('%', '')) ?? 0;
    final status = db.calculateStatus(deadline, completion);

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
            color: AppColors.blueText,
          ),
        ),
        actions: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.navbar,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blueText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.blueText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    'LAST UPDATED',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.blueText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current Project: $projectName\n'
                    'Contribution Rate: $contribution\n'
                    'Status: $status\n'
                    'Deadline: $deadline',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.blueText,
                    ),
                  ),
                  if (_userRole != 'user')
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.blueText),
                      tooltip: 'Edit Project Info',
                      onPressed: () async {
                        Navigator.pushNamed(context, '/edit_project', arguments: _projectInfo);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Your project',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blueText,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.blueText,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppColors.navbar,
        iconSize: 32,
        selectedFontSize: 14,
        unselectedFontSize: 12,
        items: _userRole == 'user'
            ? const [
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
              ]
            : const [
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
