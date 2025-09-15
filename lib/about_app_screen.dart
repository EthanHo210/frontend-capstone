import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutAppScreen extends StatelessWidget {
  final bool embedded; // if true: content-only (no Scaffold/AppBar)
  const AboutAppScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    // fallback so color is never null
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface;

    final content = _AboutAppContent(textColor: textColor);

    if (embedded) {
      // Content-only: MainDashboard supplies the outer Scaffold/AppBar/BottomNav
      return content;
    }

    // Backward-compatible standalone route
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About App',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(child: content),
    );
  }
}

/// Internal, reusable content so we don't duplicate UI between embedded and
/// standalone presentations.
class _AboutAppContent extends StatelessWidget {
  final Color textColor;
  const _AboutAppContent({required this.textColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Together!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Version 1.0.0',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          // Use SelectableText so the long description can be copied if needed.
          SelectableText(
            'Together! is a collaborative digital tool designed to enhance group collaboration among students and educators. '
            'This platform supports smart team formation, task tracking, and role-based dashboards to improve engagement, '
            'performance, and teaching assessments. Developed as part of an academic capstone project, Together! embodies '
            'the future of digital teamwork and educational support.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textColor,
            ),
            // allow the text to scale with system font size
            textScaleFactor: MediaQuery.textScaleFactorOf(context),
          ),
        ],
      ),
    );
  }
}
