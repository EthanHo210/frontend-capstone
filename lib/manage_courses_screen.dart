import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class ManageCoursesScreen extends StatefulWidget {
  /// If true returns content-only (no Scaffold/AppBar) so it can be embedded
  /// inside MainDashboard's chrome. Otherwise acts as a standalone route.
  final bool embedded;

  /// Optional callback invoked when courses list changes (add/delete/rename).
  final VoidCallback? onCoursesChanged;

  const ManageCoursesScreen({super.key, this.embedded = false, this.onCoursesChanged});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final db = MockDatabase();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _prefixController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addCourse() {
    final prefix = _prefixController.text.trim().toUpperCase();
    final id = _idController.text.trim();
    final name = _nameController.text.trim().toTitleCase();

    if (prefix.isEmpty || id.isEmpty || name.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final fullCourseName = '$prefix$id - $name';

    // 1) ID (prefix+id) conflict
    final coursesList = db.getCourses() ?? <String>[];
    final hasSameId = coursesList.any((course) {
      final existingPrefixId = course.split(RegExp(r'\s\-\s'))[0].trim();
      return existingPrefixId.toUpperCase() == '$prefix$id';
    });

    if (hasSameId) {
      _showError('A course with this prefix and ID already exists.');
      return;
    }

    // 2) Name conflict (case-insensitive)
    final hasSameName = coursesList.any((course) {
      final parts = course.split(RegExp(r'\s\-\s'));
      final existingName = parts.length > 1 ? parts[1].trim().toLowerCase() : '';
      return existingName == name.toLowerCase();
    });

    if (hasSameName) {
      _showError('A course with this name already exists.');
      return;
    }

    db.addCourse(fullCourseName);
    _prefixController.clear();
    _idController.clear();
    _nameController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
    widget.onCoursesChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course added successfully')));
  }

  void _deleteCourse(String course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Course'),
          ],
        ),
        content: Text('Are you sure you want to delete the course "$course"? '
            'This will also remove it from all associated projects.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              db.removeCourse(course);
              setState(() {});
              widget.onCoursesChanged?.call();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course deleted')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _modifyCourse(String oldCourse) {
    // split safely even if format differs
    final parts = oldCourse.split(RegExp(r'\s\-\s'));
    final prefixAndId = parts.isNotEmpty ? parts[0].trim() : '';
    final namePart = parts.length > 1 ? parts[1].trim() : '';

    // try to split prefix and numeric id (if present)
    final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(prefixAndId);
    final prefix = match != null ? (match.group(1) ?? '') : '';
    final id = match != null ? (match.group(2) ?? '') : '';

    final TextEditingController newPrefix = TextEditingController(text: prefix);
    final TextEditingController newId = TextEditingController(text: id);
    final TextEditingController newName = TextEditingController(text: namePart);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInput(newPrefix, 'Prefix'),
                const SizedBox(height: 8),
                _buildInput(newId, 'ID'),
                const SizedBox(height: 8),
                _buildInput(newName, 'Name'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  newPrefix.dispose();
                  newId.dispose();
                  newName.dispose();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final newPrefixText = newPrefix.text.trim().toUpperCase();
                  final newIdText = newId.text.trim();
                  final newNameText = newName.text.trim().toTitleCase();

                  if (newPrefixText.isEmpty || newIdText.isEmpty || newNameText.isEmpty) {
                    _showError('All fields must be filled.');
                    return;
                  }

                  final newFullName = '$newPrefixText$newIdText - $newNameText';

                  // compare only against other courses (exclude the one we are editing)
                  final otherCourses = (db.getCourses() ?? <String>[]).where((c) => c != oldCourse).toList();

                  // 1) ID conflict (prefix+id)
                  final hasIdConflict = otherCourses.any((c) {
                    final existingPrefixId = c.split(RegExp(r'\s\-\s'))[0].trim();
                    return existingPrefixId.toUpperCase() == '$newPrefixText$newIdText';
                  });

                  if (hasIdConflict) {
                    _showError('A course with this prefix and ID already exists.');
                    return;
                  }

                  // 2) Name conflict (case-insensitive)
                  final hasNameConflict = otherCourses.any((c) {
                    final parts = c.split(RegExp(r'\s\-\s'));
                    final existingName = parts.length > 1 ? parts[1].trim().toLowerCase() : '';
                    return existingName == newNameText.toLowerCase();
                  });

                  if (hasNameConflict) {
                    _showError('A course with this name already exists.');
                    return;
                  }

                  // all good — rename
                  db.renameCourse(oldCourse, newFullName);
                  newPrefix.dispose();
                  newId.dispose();
                  newName.dispose();
                  setState(() {});
                  widget.onCoursesChanged?.call();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course updated')));
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    final theme = Theme.of(context);
    final inputFillColor = theme.colorScheme.surfaceVariant;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    final searchFillColor = theme.brightness == Brightness.dark ? Colors.grey[700] : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          filled: true,
          fillColor: searchFillColor,
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCoursesRaw = db.getCourses();
    final allCourses = (allCoursesRaw is Iterable) ? List<String>.from(allCoursesRaw.map((e) => e.toString())) : <String>[];
    final courses = allCourses
        .where((course) => course.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : AppColors.blueText);
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.blue[50];

    // content-only (used in embedded mode)
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // for embedded mode we show the search field at top of the content
          if (widget.embedded) _buildSearchField(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInput(_prefixController, 'Prefix (e.g. COSC)'),
              const SizedBox(height: 8),
              _buildInput(_idController, 'ID (e.g. 1234)'),
              const SizedBox(height: 8),
              _buildInput(_nameController, 'Course Name (e.g. Engineering)'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
              child: const Text('Add Course', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: courses.isEmpty
                ? Center(
                    child: Text(
                      'No courses found.',
                      style: GoogleFonts.poppins(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                    ),
                  )
                : ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Card(
                        color: cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          title: Text(
                            course,
                            style: GoogleFonts.poppins(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: textColor),
                                onPressed: () => _modifyCourse(course),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCourse(course),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    // Standalone full-screen mode (kept for direct route)
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text(
          'Manage Courses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchField(),
        ),
      ),
      body: content,
    );
  }
}
