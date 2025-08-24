// assign_leader_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class AssignLeaderScreen extends StatefulWidget {
  final String projectName;

  /// set to true when you want this widget embedded in another Scaffold/IndexedStack
  final bool embedded;

  /// optional callback invoked when a leader is assigned (useful for embedded mode)
  final void Function(String username)? onAssigned;

  const AssignLeaderScreen({
    super.key,
    required this.projectName,
    this.embedded = false,
    this.onAssigned,
  });

  @override
  State<AssignLeaderScreen> createState() => _AssignLeaderScreenState();
}

class _AssignLeaderScreenState extends State<AssignLeaderScreen> {
  final db = MockDatabase();
  late List<String> memberUsernames;
  String? selectedLeader;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initMembers();
  }

  void _initMembers() {
    // safe lookup, avoid exceptions if project missing
    final all = db.getAllProjects();
    final project = all.firstWhere((p) => p['name'] == widget.projectName, orElse: () => <String, dynamic>{});

    List<String> members = [];

    if (project.isNotEmpty && project.containsKey('members')) {
      final raw = project['members'];
      if (raw is List) {
        // cast any dynamic list to List<String>
        members = raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        members = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    // filter to students only (defensive)
    memberUsernames = members.where((u) => db.isStudent(u)).toList();

    // try to get existing leader (may be null)
    selectedLeader = db.getProjectLeader(widget.projectName);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Assign leader in DB and update UI/callbacks.
  void assignLeader(String username) {
    db.assignLeader(widget.projectName, username);

    // update local selected leader so UI shows it immediately
    if (mounted) {
      setState(() {
        selectedLeader = username;
      });
    }

    // notify parent if embedded
    if (widget.embedded && widget.onAssigned != null) {
      widget.onAssigned!(username);
    }

    // always call external callback if provided (convenience)
    if (widget.onAssigned != null && !widget.embedded) {
      widget.onAssigned!(username);
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (memberUsernames.isEmpty) {
      return Center(
        child: Text(
          'No eligible students found in this project.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: memberUsernames.length,
      itemBuilder: (_, index) {
        final username = memberUsernames[index];
        final fullName = db.getUserByUsername(username)?['fullName'] ?? username;
        final isSelected = username == selectedLeader;

        return ListTile(
          title: Text(fullName, style: GoogleFonts.poppins(color: colorScheme.onSurface)),
          trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.secondary) : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text("Confirm Leader Assignment", style: GoogleFonts.poppins(color: colorScheme.onSurface)),
                content: Text("Are you sure you want to assign $fullName as the group leader?", style: GoogleFonts.poppins(color: colorScheme.onSurfaceVariant)),
                backgroundColor: Theme.of(context).dialogBackgroundColor,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: colorScheme.primary)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      assignLeader(username);
                      Navigator.pop(context); // close dialog
                      if (!widget.embedded) {
                        // when used as a standalone route, close the screen and return true
                        Navigator.pop(context, true);
                      } else {
                        // embedded: brief feedback via SnackBar (styled)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$fullName assigned as leader", style: GoogleFonts.poppins()),
                            backgroundColor: AppColors.blueText,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text("Confirm"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If embedded, return content only (no scaffold/appbar) so parent chrome stays visible.
    if (widget.embedded) {
      // Use SafeArea but avoid duplicating top/bottom padding (MainDashboard already has those)
      return SafeArea(top: false, bottom: false, child: _buildContent(context));
    }

    // Standalone route mode: provide its own Scaffold and AppBar (backwards compatible)
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Leader Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.primary),
        ),  
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: _buildContent(context),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
