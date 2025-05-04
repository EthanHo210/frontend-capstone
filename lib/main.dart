import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'main_dashboard.dart';
import 'start_new_project.dart';
import 'course_teams_screen.dart';
import 'project_status_screen.dart';
import 'project_schedule_screen.dart';
import 'theme_switch_screen.dart';
import 'project_planning_screen.dart';
import 'pin_verify_screen.dart';
import 'manage_users_screen.dart';
import 'update_username_screen.dart';
import 'update_email_screen.dart';
import 'update_password_screen.dart';
import 'about_app_screen.dart';
import 'help_center_screen.dart';
import 'password_reset_screen.dart';

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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/projectStatus':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ProjectStatusScreen(
              projectName: args['projectName'],
              completionPercentage: args['completionPercentage'],
              status: args['status'],
              courseName: args['courseName'], // ✅ Add this line
            ),

            );

          case '/projectSchedule':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ProjectScheduleScreen(
                projectName: args['projectName'],
                membersCount: args['membersCount'],
                deadline: args['deadline'],
              ),
            );

          // fallback routes
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const MainDashboard());
          case '/start_new_project':
            return MaterialPageRoute(builder: (_) => const StartNewProjectScreen());
          case '/projectPlanning':
            return MaterialPageRoute(builder: (_) => const ProjectPlanningScreen());
          case '/courseTeams':
            return MaterialPageRoute(builder: (_) => const CourseTeamsScreen());
          case '/admin_pin':
            return MaterialPageRoute(builder: (_) => const PinVerifyScreen());
          case '/manage_users':
            return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
          case '/update_username':
            return MaterialPageRoute(builder: (_) => const UpdateUsernameScreen());
          case '/update_email':
            return MaterialPageRoute(builder: (_) => const UpdateEmailScreen());
          case '/update_password':
            return MaterialPageRoute(builder: (_) => const UpdatePasswordScreen());
          case '/about_app':
            return MaterialPageRoute(builder: (_) => const AboutAppScreen());
          case '/help_center':
            return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
          case '/theme_settings':
            return MaterialPageRoute(
              builder: (_) => ThemeSwitchScreen(
                onToggleTheme: _toggleTheme,
                isDarkMode: _themeMode == ThemeMode.dark,
              ),
            );
          case '/passwordreset':
            return MaterialPageRoute(builder: (_) => const PasswordResetScreen());

          default:
            return null;
        }
      },
    );
  }
}
