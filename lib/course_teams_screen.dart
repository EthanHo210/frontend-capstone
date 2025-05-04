import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseTeamsScreen extends StatelessWidget {
  const CourseTeamsScreen({super.key});

  final List<Map<String, String>> _teams = const [
    {
      'name': 'Tang Sect',
      'status': 'Crisis',
      'date': 'April 15, 2024',
    },
    {
      'name': 'Beggar Clan',
      'status': 'On-track',
      'date': 'April 15, 2024',
    },
    {
      'name': 'Xiaoyao',
      'status': 'On-track',
      'date': 'April 15, 2024',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on-track':
        return Colors.green;
      case 'crisis':
        return Colors.redAccent;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
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
          'Course Teams',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.teal,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: COSC2999',
              style: GoogleFonts.poppins(
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final team = _teams[index];
                  return InkWell(
                    onTap: () {
                      // TODO: Navigate to Team Detail Screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${team['name']} tapped'),
                          duration: const Duration(milliseconds: 800),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team['date'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                team['name'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                'Status: ${team['status']}',
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(team['status'] ?? ''),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.directions_run, color: Colors.teal, size: 28),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
