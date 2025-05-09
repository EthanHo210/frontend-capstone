import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';


class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.blueText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blueText),
            ),
            const SizedBox(height: 20),
            _buildFAQTile('How do I create a project?', 'Go to "Start New Project" and follow the steps.'),
            _buildFAQTile('How do I form a team?', 'After creating a project, you can assign team members manually or automatically.'),
            _buildFAQTile('Who can manage users?', 'Only users with admin roles can access user management tools.'),
            const SizedBox(height: 30),
            Text(
              'Need more help?',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.blueText),
            ),
            const SizedBox(height: 10),
            Text(
              'Please contact our support team at\nsupport@togetherapp.com',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.blueText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: GoogleFonts.poppins(color: AppColors.blueText, fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Text(answer, style: GoogleFonts.poppins(color: AppColors.blueText)),
        )
      ],
    );
  }
}
