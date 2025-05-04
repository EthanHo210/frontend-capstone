import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class ProjectScheduleScreen extends StatefulWidget {
  final String projectName;
  final int membersCount;
  final DateTime deadline;

  const ProjectScheduleScreen({
    super.key,
    required this.projectName,
    required this.membersCount,
    required this.deadline,
  });

  @override
  State<ProjectScheduleScreen> createState() => _ProjectScheduleScreenState();
}

class _ProjectScheduleScreenState extends State<ProjectScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.teal),
        title: Text(
          'Project Schedule',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.teal,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.projectName}\n${widget.membersCount} Members - Deadline: ${_formatDate(widget.deadline)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TO DO',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.directions_run, color: Colors.teal),
                title: Text('Project Standup', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${_formatDate(DateTime(2025, 4, 15))}\nTime allotted: 30 minutes',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
