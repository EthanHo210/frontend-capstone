import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'mock_database.dart';

class ProjectScheduleScreen extends StatefulWidget {
  final String projectName;
  final int membersCount;
  final DateTime deadline;

  /// If true, renders content-only (no Scaffold/AppBar) so it can sit inside
  /// MainDashboard/DashboardScaffold without losing the global top/bottom bars.
  final bool embedded;

  const ProjectScheduleScreen({
    super.key,
    required this.projectName,
    required this.membersCount,
    required this.deadline,
    this.embedded = false,
  });

  @override
  State<ProjectScheduleScreen> createState() => _ProjectScheduleScreenState();
}

class _ProjectScheduleScreenState extends State<ProjectScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Widget _buildBody(BuildContext context, {required bool showLocalHeader}) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    final isAdmin = role == 'admin';

    // adaptive colors from the current theme
    final textColor = Theme.of(context).textTheme.bodyLarge?.color
        ?? Theme.of(context).colorScheme.onSurface;
    final subTextColor = Theme.of(context).textTheme.bodyMedium?.color
        ?? Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (isAdmin) {
      return SafeArea(
        top: !widget.embedded, // parent header handles insets when embedded
        bottom: false,
        child: Center(
          child: Text(
            'Admins are not allowed to access the project schedule.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: !widget.embedded,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLocalHeader) ...[
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Project Schedule',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            Text(
              '${widget.projectName}\n${widget.membersCount} Members - Deadline: ${_formatDate(widget.deadline)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Calendar
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                          color: primaryColor.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: GoogleFonts.poppins(color: Colors.white),
                        selectedTextStyle: GoogleFonts.poppins(color: Colors.white),
                        defaultTextStyle: GoogleFonts.poppins(color: textColor),
                        weekendTextStyle: GoogleFonts.poppins(color: textColor),
                        outsideTextStyle: GoogleFonts.poppins(
                          color: textColor.withOpacity(0.6), // fixed ?. issue
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TO DO heading + sample item(s)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TO DO',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.directions_run, color: primaryColor),
                        title: Text(
                          'Project Standup',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatDate(DateTime.now().add(const Duration(days: 7)))}\nTime allotted: 30 minutes',
                          style: GoogleFonts.poppins(color: subTextColor),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    // Add more TODO items here…
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Content-only: parent provides AppBar/BottomNav via DashboardScaffold.
      return _buildBody(context, showLocalHeader: false);
    }

    // Standalone: keep a local Scaffold (useful when pushed as a route).
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Project Schedule',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: _buildBody(context, showLocalHeader: false), // AppBar already shown
    );
  }
}
