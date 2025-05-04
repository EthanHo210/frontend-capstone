import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StartNewProjectScreen extends StatefulWidget {
  const StartNewProjectScreen({super.key});

  @override
  State<StartNewProjectScreen> createState() => _StartNewProjectScreenState();
}

class _StartNewProjectScreenState extends State<StartNewProjectScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupSizeController = TextEditingController();

  void _confirmProject() {
  final groupName = _groupNameController.text.trim();
  final groupSize = _groupSizeController.text.trim();

  if (groupName.isEmpty || groupSize.isEmpty) {
    _showDialog('Please fill in all fields.');
    return;
  }

  // Optionally validate that group size is a number
  if (int.tryParse(groupSize) == null || int.parse(groupSize) <= 0) {
    _showDialog('Please enter a valid group size.');
    return;
  }

  // All good → proceed
  Navigator.pushNamed(context, '/projectPlanning');
}


  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Project', style: GoogleFonts.poppins()),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.teal),
        title: Text(
          'Start Your Project',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _buildInputField(_groupNameController, 'Group Name'),
            const SizedBox(height: 20),
            _buildInputField(_groupSizeController, 'Number of Group Members'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: _confirmProject, // <== THIS FIXES IT
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'CONFIRM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: hint.contains('Number') ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(),
        filled: true,
        fillColor: Colors.greenAccent.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
