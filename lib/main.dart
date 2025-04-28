import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'main_dashboard.dart';
import 'start_new_project.dart';
import 'password_reset_screen.dart';
import 'project_planning_screen.dart';
import 'course_teams_screen.dart';
import 'pin_verify_screen.dart';
import 'manage_users_screen.dart';

void main() {
  runApp(const TogetherApp());
}

class TogetherApp extends StatelessWidget {
  const TogetherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Together!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFEFBEA),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const MainDashboard(),
        '/passwordreset': (context) => const PasswordResetScreen(),
        '/start_new_project': (context) => const StartNewProjectScreen(),
        '/projectPlanning': (context) => const ProjectPlanningScreen(),
        '/courseTeams': (context) => const CourseTeamsScreen(),
        '/admin_pin': (context) => const PinVerifyScreen(),
        '/manage_users': (context) => const ManageUsersScreen(),

      },
    );
  }
}
