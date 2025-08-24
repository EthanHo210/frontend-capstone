// help_center_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterScreen extends StatelessWidget {
  final bool embedded;
  const HelpCenterScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onBackground;

    final content = _HelpCenterContent (textColor: textColor);

    if (embedded) {
      // Content-only: MainDashboard supplies the outer Scaffold/AppBar/BottomNav
      return content;
    }

    // standalone route
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SafeArea(child: content),
    );
  }
}

class _HelpCenterContent extends StatelessWidget {
  final Color textColor;
  const _HelpCenterContent({super.key, required this.textColor});
  

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleColor = textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onBackground;
    final bodyColor = textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onBackground;
    final iconColor = Theme.of(context).iconTheme.color ?? titleColor;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildFAQTile(
            context,
            'How do I create a project?',
            'Go to "Start New Project" and follow the steps.',
            titleColor,
            bodyColor,
            iconColor,
          ),
          _buildFAQTile(
            context,
            'How do I form a team?',
            'After creating a project, you can assign team members manually or automatically.',
            titleColor,
            bodyColor,
            iconColor,
          ),
          _buildFAQTile(
            context,
            'Who can manage users?',
            'Only users with admin roles can access user management tools.',
            titleColor,
            bodyColor,
            iconColor,
          ),
          const SizedBox(height: 30),
          Text(
            'Need more help?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            'Please contact our support team at\nsupport@togetherapp.com',
            style: GoogleFonts.poppins(fontSize: 16, color: bodyColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(
    BuildContext context,
    String question,
    String answer,
    Color questionColor,
    Color answerColor,
    Color iconColor,
  ) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.poppins(
          color: questionColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      collapsedTextColor: questionColor,
      textColor: questionColor,
      collapsedIconColor: iconColor,
      iconColor: iconColor,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: GoogleFonts.poppins(color: answerColor),
          ),
        ),
      ],
    );
  }

}
