import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';

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

  void _addCourse() {
    final prefix = _prefixController.text.trim();
    final id = _idController.text.trim();
    final name = _nameController.text.trim();

    if (prefix.isEmpty || id.isEmpty || name.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    final fullCourseName = '$prefix$id - $name';

    if (!db.getCourses().contains(fullCourseName)) {
      db.addCourse(fullCourseName);
      _prefixController.clear();
      _idController.clear();
      _nameController.clear();
      setState(() {});
    } else {
      _showError('Course already exists.');
    }
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
    final parts = oldCourse.split(RegExp(r'[\s\-]+'));
    final prefix = parts.isNotEmpty ? parts[0].substring(0, 4) : '';
    final id = parts.isNotEmpty ? parts[0].substring(4) : '';
    final name = parts.length > 1 ? parts.sublist(1).join(' ') : '';

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
              final newFullName = '${newPrefix.text.trim()}${newId.text.trim()} - ${newName.text.trim()}';
              if (newPrefix.text.isEmpty || newId.text.isEmpty || newName.text.isEmpty) {
                _showError('All fields must be filled.');
                return;
              }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = db.getCourses();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.blueText),
        title: Text(
          'Manage Courses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.blueText),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInput(_prefixController, 'Prefix (e.g. COSC)')),
                const SizedBox(width: 8),
                Expanded(child: _buildInput(_idController, 'ID (e.g. 1234)')),
                const SizedBox(width: 8),
                Expanded(child: _buildInput(_nameController, 'Course Name (e.g. Engineering)')),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
              child: const Text('Add Course', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      title: Text(course, style: GoogleFonts.poppins()),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
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
