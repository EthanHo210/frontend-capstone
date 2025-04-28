import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  final bool isAdmin; 

  const SettingsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFBEA),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.teal[800],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal[800]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(context, icon: Icons.person, title: 'Update Username', onTap: () {}),
          _buildSettingsTile(context, icon: Icons.email, title: 'Update Email', onTap: () {}),
          _buildSettingsTile(context, icon: Icons.lock, title: 'Change Password', onTap: () {}),

          const SizedBox(height: 30),

          Text(
            'App Settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(context, icon: Icons.notifications, title: 'Notifications', onTap: () {}),
          _buildSettingsTile(context, icon: Icons.brightness_6, title: 'Theme', onTap: () {}),

          const SizedBox(height: 30),

          if (isAdmin) // <-- Only show if user is admin
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: Icons.manage_accounts,
                  title: 'Manage Users',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin_pin');
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),

          Text(
            'Support',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
          const SizedBox(height: 10),
          _buildSettingsTile(context, icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
          _buildSettingsTile(context, icon: Icons.info_outline, title: 'About App', onTap: () {}),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal[800]),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.teal[900],
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
