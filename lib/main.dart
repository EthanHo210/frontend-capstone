import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

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
      },
    );
  }
}

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
    final userEmail = args?['email'] ?? 'Guest';
    final username = args?['username'] ?? userEmail.split('@')[0];
    final isLoggedIn = userEmail != 'Guest';

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Together!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
          actions: [
            if (isLoggedIn)
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.teal[100],
                    child: const Icon(Icons.person, size: 18, color: Colors.teal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      color: Colors.teal[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(color: Colors.teal[800]),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              )
            else
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Sign In'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _buildDashboardCard(
                context,
                title: 'Project Management',
                icon: Icons.assignment,
                color: Colors.amber[200]!,
                onTap: () {},
              ),
              _buildDashboardCard(
                context,
                title: 'Group Formation',
                icon: Icons.group,
                color: Colors.lightBlue[100]!,
                onTap: () {},
              ),
              _buildDashboardCard(
                context,
                title: 'Tracking',
                icon: Icons.track_changes,
                color: Colors.green[100]!,
                onTap: () {},
              ),
              _buildDashboardCard(
                context,
                title: 'Analytics',
                icon: Icons.analytics,
                color: Colors.purple[100]!,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(2, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.teal[900]),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
