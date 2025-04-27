import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    final userEmail = args?['email'] ?? 'Guest';
    final username = args?['username'] ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Text(
                    'Together!',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  // Profile + Sign Out
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
                            color: Colors.teal[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.teal[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Project Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAST UPDATED',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Project : ...',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  Text(
                    'Contribution rate : ...',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  Text(
                    'Rank : Frequent Contributor',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Big Title
            Center(
              child: Text(
                'Your project',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[900],
                ),
              ),
            ),

            const Spacer(),

            // Bottom Navigation Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavIconButton(Icons.lightbulb, 'Start New', () {
                    // TODO: Navigate to Start Project
                  }),
                  _buildNavIconButton(Icons.assignment, 'Projects', () {
                    // TODO: Navigate to Project Management
                  }),
                  _buildNavIconButton(Icons.search, 'Tracking', () {
                    // TODO: Navigate to Tracking/Analytics
                  }),
                  _buildNavIconButton(Icons.settings, 'Settings', () {
                    // TODO: Navigate to Settings/Profile
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIconButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.teal[800]),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }
}
