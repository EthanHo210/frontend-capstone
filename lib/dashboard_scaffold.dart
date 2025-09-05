// dashboard_scaffold.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScaffold extends StatelessWidget {
  final Widget body;
  final Widget? appBarTitle;
  final String? displayName;
  final List<BottomNavigationBarItem> bottomItems;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBack;
  final VoidCallback? onBack;

  const DashboardScaffold({
    Key? key,
    required this.body,
    required this.bottomItems,
    required this.currentIndex,
    this.onTap,
    this.appBarTitle,
    this.displayName,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBack = false,
    this.onBack,
  }) : super(key: key);

  Widget _defaultTitle(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(
        'To',
        style: GoogleFonts.kavoon(
          textStyle: const TextStyle(
            color: Colors.red,
            fontSize: 35,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)
            ],
          ),
        ),
      ),
      Text(
        'gether!',
        style: GoogleFonts.kavoon(
          textStyle: const TextStyle(
            color: Color.fromRGBO(42, 49, 129, 1),
            fontSize: 35,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(offset: Offset(4.0, 4.0), blurRadius: 1.5, color: Colors.white)
            ],
          ),
        ),
      ),
    ]);
  }

  void _handleNavTap(BuildContext context, int index) {
    const routes = [
      '/start_new_project',
      '/course_projects',
      '/projectStatus',
      '/settings',
      '/admin_main_hub',
    ];

    if (index >= 0 && index < routes.length) {
      Navigator.pushNamedAndRemoveUntil(context, routes[index], (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navColor = Theme.of(context).textTheme.bodyMedium?.color ?? Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: appBarTitle ?? _defaultTitle(context),
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack ?? () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (displayName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text(
                      displayName!.isNotEmpty ? displayName![0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: navColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      displayName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: navColor),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: navColor,
        unselectedItemColor: navColor,
        selectedIconTheme: IconThemeData(color: navColor),
        unselectedIconTheme: IconThemeData(color: navColor),
        showUnselectedLabels: true,
        currentIndex: (currentIndex < bottomItems.length) ? currentIndex : 0,
        onTap: (i) {
          if (onTap != null) {
            onTap!(i);
          } else {
            _handleNavTap(context, i);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        items: bottomItems,
      ),
      floatingActionButton: (floatingActionButton == null)
        ? null
        : HeroMode(enabled: false, child: floatingActionButton!),
      floatingActionButtonLocation: floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}
