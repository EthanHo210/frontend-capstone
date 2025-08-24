import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

class ProjectPlanningScreen extends StatefulWidget {
  /// When true, render content-only (no Scaffold/AppBar) so it can be embedded
  /// inside MainDashboard / DashboardScaffold.
  final bool embedded;

  /// Optional callback for the Next action when embedded (e.g., switch tab or
  /// open SelectCourses). If null, standalone fallback is used.
  final VoidCallback? onNext;

  const ProjectPlanningScreen({
    super.key,
    this.embedded = false,
    this.onNext,
  });

  @override
  State<ProjectPlanningScreen> createState() => _ProjectPlanningScreenState();
}

class _ProjectPlanningScreenState extends State<ProjectPlanningScreen> {
  final Map<String, bool> _responsibilities = {
    'Report Writing': false,
    'Development': false,
    'Data Elicitation': false,
    'Slide Preparation': false,
    'Developer': false,
    'Project Manager': false,
  };

  void _goNext() {
    // In embedded mode, delegate to parent so the global chrome stays put
    if (widget.embedded && widget.onNext != null) {
      widget.onNext!();
      return;
    }
    // Standalone fallback: go to Select Course (courseTeams needs args)
    Navigator.pushNamed(context, '/selectCourse');
  }

  void _clearAll() {
    setState(() {
      for (final k in _responsibilities.keys) {
        _responsibilities[k] = false;
      }
    });
  }

  Widget _buildContent(BuildContext context) {
    final db = MockDatabase();
    final role = db.getUserRole(db.currentLoggedInUser ?? '');
    final isAdmin = role == 'admin';

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final headingColor = isDarkMode ? Colors.white : AppColors.blueText;
    final bodyColor = isDarkMode ? Colors.white70 : AppColors.blueText;

    if (isAdmin) {
      return Center(
        child: Text(
          'Admins are not allowed to access project planning.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: headingColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return SafeArea(
      top: false, // let parent AppBar handle top inset when embedded
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Project Planning',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Before starting your project, please arrange the project responsibilities.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: bodyColor,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Select Your Responsibilities:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable list
            Expanded(
              child: ListView(
                children: _responsibilities.keys.map((key) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: headingColor,
                      ),
                    ),
                    value: _responsibilities[key],
                    activeColor: scheme.primary,
                    checkColor: scheme.onPrimary,
                    onChanged: (value) {
                      setState(() {
                        _responsibilities[key] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
            ),

            // Bottom actions (inside content so global bottom nav stays visible)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.primary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _goNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
    // Embedded: return content only (no local Scaffold/AppBar)
    if (widget.embedded) {
      return _buildContent(context);
    }

    // Standalone: keep a local Scaffold for backwards compatibility
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildContent(context),
    );
  }
}
