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
  const ManageCoursesScreen({super.key});

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

  void _addCourse() {
    final prefix = _prefixController.text.trim().toUpperCase();
    final id = _idController.text.trim();
    final name = _nameController.text.trim().toTitleCase();

    if (prefix.isEmpty || id.isEmpty || name.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final fullCourseName = '$prefix$id - $name';

    // 1️⃣ Check if the same prefix+ID already exists
    final hasSameId = db.getCourses().any((course) {
      final existingPrefixId = course.split(' - ')[0];
      return existingPrefixId == '$prefix$id';
    });

    if (hasSameId) {
      _showError('A course with this prefix and ID already exists.');
      return;
    }

    // 2️⃣ Check if the same course name already exists (case-insensitive)
    final hasSameName = db.getCourses().any((course) {
      final existingName = course.split(' - ')[1].toLowerCase();
      return existingName == name.toLowerCase();
    });

    if (hasSameName) {
      _showError('A course with this name already exists.');
      return;
    }

    // 3️⃣ Add course if it's completely unique
    db.addCourse(fullCourseName);
    _prefixController.clear();
    _idController.clear();
    _nameController.clear();
    setState(() {});
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
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _modifyCourse(String oldCourse) {
    final parts = oldCourse.split(RegExp(r'\s\-\s'));
    final prefixAndId = parts.isNotEmpty ? parts[0].trim() : '';
    final name = parts.length > 1 ? parts[1].trim() : '';

    // use regex to separate letters (prefix) and digits (id)
    final match = RegExp(r'^([A-Za-z]+)(\d+)$').firstMatch(prefixAndId);
    final prefix = match != null ? (match.group(1) ?? '') : '';
    final id = match != null ? (match.group(2) ?? '') : '';

    final newPrefix = TextEditingController(text: prefix);
    final newId = TextEditingController(text: id);
    final newName = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
              final otherCourses = db.getCourses().where((c) => c != oldCourse).toList();

              // 1) ID conflict (prefix+id)
              final hasIdConflict = otherCourses.any((c) {
                final existingPrefixId = c.split(RegExp(r'\s\-\s'))[0].trim();
                return existingPrefixId == '$newPrefixText$newIdText';
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
              setState(() {});
              Navigator.pop(context);
            },

            child: const Text('Save'),
          ),
        ],
      ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor =
        isDarkMode ? Colors.grey[700] : Colors.blue[50];

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

  @override
  Widget build(BuildContext context) {
    final allCourses = db.getCourses();
    final courses = allCourses
        .where((course) =>
            course.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
      ..sort();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDarkMode ? Colors.white : AppColors.blueText;
    final cardColor =
        isDarkMode ? Colors.grey[800] : Colors.blue[50];
    final searchFillColor =
        isDarkMode ? Colors.grey[700] : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text(
          'Manage Courses',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                filled: true,
                fillColor: searchFillColor,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
            ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
              ),
              child: const Text(
                'Add Course',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }
}
