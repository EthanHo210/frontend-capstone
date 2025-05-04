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
import 'update_username_screen.dart';
import 'update_email_screen.dart';
import 'update_password_screen.dart';
import 'about_app_screen.dart';
import 'help_center_screen.dart';
import 'theme_switch_screen.dart';

void main() {
  runApp(const TogetherApp());
}

class TogetherApp extends StatefulWidget {
  const TogetherApp({super.key});

  @override
  State<TogetherApp> createState() => _TogetherAppState();
}

class _TogetherAppState extends State<TogetherApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Together!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFEFBEA), // light cream for light mode
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // deep dark for dark mode
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: _themeMode,
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
        '/update_username': (context) => const UpdateUsernameScreen(),
        '/update_email': (context) => const UpdateEmailScreen(),
        '/update_password': (context) => const UpdatePasswordScreen(),
        '/about_app': (context) => const AboutAppScreen(),
        '/help_center': (context) => const HelpCenterScreen(),
        '/theme_settings': (context) => ThemeSwitchScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
      },
    );
  }
}
