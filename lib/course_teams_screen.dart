import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseTeamsScreen extends StatelessWidget {
  const CourseTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Course Teams',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Course: COSC2999',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTeamCard('Tang Sect', 'Crisis', context),
            _buildTeamCard('Beggar Clan', 'On-track', context),
            _buildTeamCard('Xiaoyao', 'On-track', context),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(String teamName, String status, BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'April 15, 2024',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
        title: Text(
          teamName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Status: $status',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: const Icon(Icons.directions_run, color: Colors.black87),
        onTap: () {
          Navigator.pushNamed(context, '/projectschedule');
        },
      ),
    );
  }
}
