import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';


class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About App',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Together!',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.blueText),
            ),
            const SizedBox(height: 10),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(fontSize: 18, color: AppColors.blueText),
            ),
            const SizedBox(height: 20),
            Text(
              'Together! is a collaborative digital tool designed to enhance group collaboration among students and educators. '
              'This platform supports smart team formation, task tracking, and role-based dashboards to improve engagement, '
              'performance, and teaching assessments. Developed as part of an academic capstone project, Together! embodies '
              'the future of digital teamwork and educational support.',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.blueText),
            ),
          ],
        ),
      ),

      
    );
  }
}
