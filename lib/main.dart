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
import 'manage_users_screen.dart';
import 'update_password_screen.dart';
import 'about_app_screen.dart';
import 'help_center_screen.dart';
import 'password_reset_screen.dart';
import 'edit_project_screen.dart';
import 'admin_dashboard.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'user_logs_screen.dart';
import 'select_courses_screen.dart';
import 'manage_courses_screen.dart';

void main() {
  runApp(const TogetherApp());
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

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

            if (role == 'admin' || role == 'officer') {
              return MaterialPageRoute(builder: (_) => const AdminDashboard());
            } else {
              return MaterialPageRoute(builder: (_) => const MainDashboard());
            }
          case '/start_new_project':
            return MaterialPageRoute(builder: (_) => const StartNewProjectScreen());
          case '/projectPlanning':
            return MaterialPageRoute(builder: (_) => const ProjectPlanningScreen());
          case '/selectCourse':
            final db = MockDatabase();
            final user = db.currentLoggedInUser ?? '';
            final username = db.getUsernameByEmail(user) ?? user;
            final projects = db.getAllProjects();
            final Set<String> visibleCourses = projects
                .where((project) {
                  final members = project['members'] is List
                      ? List<String>.from(project['members'])
                      : (project['members'] as String).split(',').map((e) => e.trim()).toList();
                  return members.contains(username);
                })
                .map((project) => project['course'] as String)
                .where((course) => course.isNotEmpty && course != 'N/A')
                .toSet();
            return MaterialPageRoute(
              builder: (_) => SelectCoursesScreen(courses: visibleCourses.toList()),
            );
          case '/courseTeams':
            final args = settings.arguments as Map<String, dynamic>;
            final selectedCourse = args['selectedCourse'] as String;
            return MaterialPageRoute(builder: (_) => CourseTeamsScreen(selectedCourse: selectedCourse));
          case '/manage_users':
            return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
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
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => EditProjectScreen(project: args),
            );
          case '/user_logs':
            return MaterialPageRoute(builder: (_) => const UserLogsScreen());
          case '/main_dashboard':
            return MaterialPageRoute(builder: (_) => const MainDashboard());
          case '/manage_courses':
            return MaterialPageRoute(builder: (_) => const ManageCoursesScreen());

          default:
            return null;
        }
      },
      navigatorObservers: [routeObserver],
    );
  }
}
