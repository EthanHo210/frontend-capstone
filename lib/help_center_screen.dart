import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.blueText;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildFAQTile(
              context,
              'How do I create a project?',
              'Go to "Start New Project" and follow the steps.',
            ),
            _buildFAQTile(
              context,
              'How do I form a team?',
              'After creating a project, you can assign team members manually or automatically.',
            ),
            _buildFAQTile(
              context,
              'Who can manage users?',
              'Only users with admin roles can access user management tools.',
            ),
            const SizedBox(height: 30),
            Text(
              'Need more help?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please contact our support team at\nsupport@togetherapp.com',
              style: GoogleFonts.poppins(fontSize: 16, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.blueText;

    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Text(
            answer,
            style: GoogleFonts.poppins(color: textColor),
          ),
        )
      ],
    );
  }
}
