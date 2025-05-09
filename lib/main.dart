import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
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
import 'edit_project_screen.dart';
import 'admin_dashboard.dart';
import 'mock_database.dart';

void main() {
  runApp(const TogetherApp());
}

class AppColors {
  static const blueText = Color(0xFF2C348B); // Deep logo blue
  static const redText = Color(0xFFC62828);  // Red for 'T'
  static const background = Color(0xFFF4F4FD); // Soft lavender
  static const navbar = Color(0xFFDDE3F5); // Light blue nav bar
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
      title: 'Together!'
      ,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.blueText,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navbar,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.blueText),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.navbar,
          selectedItemColor: AppColors.blueText,
          unselectedItemColor: Colors.grey,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: AppColors.blueText,
          displayColor: AppColors.blueText,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.blueText,
          secondary: AppColors.navbar,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
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
                courseName: args['courseName'],
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

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/dashboard':
            final db = MockDatabase();
            final user = db.currentLoggedInUser;
            final role = user != null ? db.getUserRole(user) : 'user';

            if (role == 'admin') {
              return MaterialPageRoute(builder: (_) => const AdminDashboard());
            } else {
              return MaterialPageRoute(builder: (_) => const MainDashboard());
            }

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
          case '/edit_project':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => EditProjectScreen(project: args),
            );
          default:
            return null;
        }
      },
    );
  }
}
