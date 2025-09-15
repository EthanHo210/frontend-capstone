import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NEW
import 'app_colors.dart';
import 'mock_database.dart';

class SettingsScreen extends StatefulWidget {
  final bool isAdmin;

  /// When provided, these let Settings open the embedded pages in MainDashboard
  /// instead of pushing standalone routes.
  final VoidCallback? onOpenAbout;
  final VoidCallback? onOpenMembers;
  final VoidCallback? onOpenHelpCenter;
  final VoidCallback? onOpenUpdatePassword;

  /// Pass the current theme state and a toggle callback from the app root.
  final bool isDarkMode;
  final void Function(bool)? onToggleTheme;

  /// If true (default) render content-only (no Scaffold/AppBar) so it can live
  /// inside MainDashboard/DashboardScaffold. Set false for standalone.
  final bool embedded;

  const SettingsScreen({
    super.key,
    required this.isAdmin,
    this.onOpenAbout,
    this.onOpenMembers,
    this.onOpenHelpCenter,
    this.onOpenUpdatePassword,
    this.isDarkMode = false,
    this.onToggleTheme,
    this.embedded = true,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;

  // Notifications toggle state
  String _username = '';
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;

    // Load notifications setting for current user
    final db = MockDatabase();
    final id = db.currentLoggedInUser ?? '';
    _username = db.getUsernameByEmail(id) ?? id; // normalize to username
    _notifEnabled = _username.isNotEmpty
        ? db.isNotificationsEnabled(_username)
        : true; // default ON if somehow empty
  }

  void _handleThemeChange(bool value) {
    setState(() => _isDarkMode = value);
    widget.onToggleTheme?.call(value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark Mode ON' : 'Light Mode ON', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.blueText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationsChange(bool value) {
    setState(() => _notifEnabled = value);
    if (_username.isNotEmpty) {
      MockDatabase().setNotificationsEnabled(_username, value);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Notifications ON' : 'Notifications OFF', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.blueText,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      setState(() => _isDarkMode = widget.isDarkMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color textColor = brightness == Brightness.dark ? Colors.white : AppColors.blueText;
    final IconThemeData iconTheme = IconThemeData(color: textColor);

    final Widget content = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Account',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),

        _buildSettingsTile(
          context,
          icon: Icons.lock,
          title: 'Change Password',
          onTap: () {
            if (widget.onOpenUpdatePassword != null) {
              widget.onOpenUpdatePassword!(); // open embedded page in MainDashboard
            } else {
              Navigator.pushNamed(context, '/update_password'); // fallback standalone route
            }
          },
          textColor: textColor,
        ),

        const SizedBox(height: 30),

        Text('App Settings',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),

        SwitchListTile(
          value: _notifEnabled,
          onChanged: _handleNotificationsChange,
          title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
          secondary: Icon(Icons.notifications, color: textColor),
          activeThumbColor: AppColors.blueText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        SwitchListTile(
          value: _isDarkMode,
          onChanged: _handleThemeChange,
          title: Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 16, color: textColor)),
          secondary: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode, color: textColor),
          activeThumbColor: AppColors.blueText,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        const SizedBox(height: 30),

        Text('Support',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 10),
        _buildSettingsTile(
          context,
          icon: Icons.help_outline,
          title: 'Help Center',
          onTap: () {
            if (widget.onOpenHelpCenter != null) {
              widget.onOpenHelpCenter!();
            } else {
              Navigator.pushNamed(context, '/help_center');
            }
          },
          textColor: textColor,
        ),
        _buildSettingsTile(
          context,
          icon: Icons.info_outline,
          title: 'About App',
          onTap: () {
            if (widget.onOpenAbout != null) {
              widget.onOpenAbout!();
            } else {
              Navigator.pushNamed(context, '/about_app');
            }
          },
          textColor: textColor,
        ),

        const SizedBox(height: 20),

        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Log Out',
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Confirm Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Clear persisted session + mock session
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('loggedInUser');
                      MockDatabase().logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    },
                    child: Text('Log Out', style: GoogleFonts.poppins(color: AppColors.blueText)),
                  ),
                ],
              ),
            );
          },
          textColor: textColor,
        ),
      ],
    );

    if (widget.embedded) {
      return SafeArea(top: false, bottom: false, child: content);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: iconTheme,
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final color = textColor ?? AppColors.blueText;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16, color: color)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
