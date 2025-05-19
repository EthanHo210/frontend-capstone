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
  final TextEditingController _courseController = TextEditingController();

  void _addCourse() {
    final courseName = _courseController.text.trim();
    if (courseName.isEmpty) return;

    if (!db.getCourses().contains(courseName)) {
      db.addCourse(courseName);
      _courseController.clear();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course already exists.')),
      );
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.blueText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _courseController,
              decoration: InputDecoration(
                hintText: 'Enter new course name',
                filled: true,
                fillColor: Colors.blue[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueText,
              ),
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
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCourse(course),
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
