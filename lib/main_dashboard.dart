import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });

  if (index == 0) {
    Navigator.pushNamed(context, '/start_new_project'); // <-- Add this
  }
}


  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    final userEmail = args?['email'] ?? 'Guest';
    final username = args?['username'] ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Together!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
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
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(color: Colors.teal),
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
            Text(
              'Current Project : ...\nContribution rate : ...\nRank : Frequent Contributor',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Your project',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Optionally, add a little content based on _selectedIndex if needed
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
        iconSize: 32, // ⬅️ Bigger icons
        selectedFontSize: 14, // ⬅️ Bigger selected label text
        unselectedFontSize: 12, // ⬅️ Unselected label text slightly smaller
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
