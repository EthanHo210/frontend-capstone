import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class SettingsScreen extends StatefulWidget {
  final bool isAdmin;

  /// Optional: pass current theme state and a toggle callback from your app root.
  /// This keeps compatibility if you don't provide them right away.
  final bool isDarkMode;
  final void Function(bool)? onToggleTheme;

  const SettingsScreen({
    super.key,
    required this.isAdmin,
    this.isDarkMode = false,
    this.onToggleTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void _handleThemeChange(bool value) {
    setState(() => _isDarkMode = value);

    // call app-level callback if provided (this is how you should change the whole app theme)
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!(value);
    }

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
  }

  @override
  Widget build(BuildContext context) {
    
    

    // Dynamic color: blue in light mode, white in dark mode
    final brightness = Theme.of(context).brightness;
    final Color textColor = brightness == Brightness.dark ? Colors.white : AppColors.blueText;
    final IconThemeData iconTheme = IconThemeData(color: textColor);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: iconTheme,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              Navigator.pushNamed(context, '/update_password');
            },
            textColor: textColor,
          ),

          const SizedBox(height: 30),

          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
            textColor: textColor,
          ),

          // MOVED: Theme toggle inline (no separate screen)
          // This allows everyone (admins/officers included) to toggle the app theme.
          SwitchListTile(
            value: _isDarkMode,
            onChanged: (value) => _handleThemeChange(value),
            title: Text(
              'Dark Mode',
              style: GoogleFonts.poppins(fontSize: 16, color: textColor),
            ),
            secondary: Icon(
              _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: textColor,
            ),
            activeColor: AppColors.blueText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0), // match ListTile
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // match ListTile style
            ),
          ),

          const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    Navigator.pushNamed(context, '/help_center');
                  },
                  textColor: textColor,
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About App',
                  onTap: () {
                    Navigator.pushNamed(context, '/about_app');
                  },
                  textColor: textColor,
                ),
              ],
            ),

          const SizedBox(height: 20),

          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      'Confirm Logout',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Are you sure you want to log out?',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Cancel
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Log Out',
                          style: GoogleFonts.poppins(color: AppColors.blueText),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? textColor}) {
    final color = textColor ?? AppColors.blueText;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: color,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
