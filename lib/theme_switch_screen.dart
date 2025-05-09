import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class ThemeSwitchScreen extends StatefulWidget {
  final void Function(bool isDark) onToggleTheme;
  final bool isDarkMode;

  const ThemeSwitchScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<ThemeSwitchScreen> createState() => _ThemeSwitchScreenState();
}

class _ThemeSwitchScreenState extends State<ThemeSwitchScreen> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    final isAdmin = role == 'admin';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Theme Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: isAdmin
          ? Center(
              child: Text(
                'Admins are not allowed to change the theme.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.blueText,
                ),
              ),
            )
          : Center(
              child: SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: GoogleFonts.poppins(fontSize: 20),
                ),
                value: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                    widget.onToggleTheme(value);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Dark Mode ON' : 'Light Mode ON',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppColors.blueText,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
    );
  }
}