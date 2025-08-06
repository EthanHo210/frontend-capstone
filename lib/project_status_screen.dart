import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'assign_leader_screen.dart';
import 'assign_task_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class ProjectStatusScreen extends StatefulWidget {
  final String projectName;
  final String courseName;

  const ProjectStatusScreen({
    super.key,
    required this.projectName,
    required this.courseName,
  });

  @override
  State<ProjectStatusScreen> createState() => _ProjectStatusScreenState();
}

class _ProjectStatusScreenState extends State<ProjectStatusScreen> {
  final db = MockDatabase();
  late Map<String, dynamic> project;
  late String currentUsername;
  late String role;
  late bool isLeader;
  late List<Map<String, dynamic>> tasks;
  late List<String> projectMembers;

  @override
  void initState() {
    super.initState();
    currentUsername = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ?? db.currentLoggedInUser ?? '';
    role = db.getUserRole(currentUsername);
    project = db.getAllProjects().firstWhere((p) => p['name'] == widget.projectName);
    isLeader = db.getProjectLeader(widget.projectName) == currentUsername;
    tasks = db.getTasksForProject(widget.projectName);
    projectMembers = db.getProjectMembers(widget.projectName);
  }

  double getCompletionPercentage() {
    if (tasks.isEmpty) return 0;
    final confirmed = tasks.where((task) {
      final subtasks = (task['subtasks'] ?? []) as List<dynamic>;
      if (subtasks.isEmpty) return false;
      final approvedCount = subtasks.where((s) => s['status'] == 'Approved').length;
      return approvedCount == subtasks.length;
    }).length;
    return (confirmed / tasks.length) * 100;
  }

  void showSubmitDialog(Map<String, dynamic> task, int subtaskIndex) async {
    String comment = '';
    Uint8List? imageBytes;
    final picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Confirm Finish'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setModalState(() {
                      imageBytes = bytes;
                    });
                  }
                },
                icon: const Icon(Icons.image),
                label: const Text("Upload Proof Image"),
              ),
              if (imageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.memory(imageBytes!, height: 100),
                ),
              TextField(
                decoration: const InputDecoration(labelText: 'Comment'),
                onChanged: (val) => comment = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (imageBytes != null || comment.trim().isNotEmpty) {
                  final confirmSubmit = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Submit Subtask"),
                      content: const Text("Are you sure you want to submit this subtask for review?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );

                  if (confirmSubmit == true) {
                    final proofPath = imageBytes != null ? base64Encode(imageBytes!) : '';
                    db.submitSubtaskProof(
                      widget.projectName,
                      task['id'],
                      subtaskIndex,
                      currentUsername,
                      comment,
                      proofPath,
                    );

                    setState(() {
                      tasks = db.getTasksForProject(widget.projectName);
                    });

                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTaskCard(Map<String, dynamic> task) {
    final subtasks = (task['subtasks'] ?? []) as List<dynamic>;
    final canEdit = ['admin', 'officer', 'teacher'].contains(role) || isLeader;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  subtasks.every((s) => s['status'] == 'Approved') ? Icons.check_circle : Icons.pending,
                  color: subtasks.every((s) => s['status'] == 'Approved') ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(task['title'] ?? 'Unnamed Task', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Assigned to: ${task['assignedTo']}'),
            const SizedBox(height: 8),
            ...List.generate(subtasks.length, (i) {
              final sub = subtasks[i];
              final votes = Map<String, bool>.from(sub['votes'] ?? {});
              final status = sub['status'];
              final proof = sub['proof'] ?? '';
              final comment = sub['comment'] ?? '';
              final alreadyVoted = votes.containsKey(currentUsername);
              final isAssignedToMe = task['assignedTo'] == currentUsername;
              final hasSubmitted = proof.isNotEmpty || comment.isNotEmpty;

              bool allOthersVoted = projectMembers
                  .where((m) => m != task['assignedTo'])
                  .every((m) => votes.containsKey(m));

              return Row(
                children: [
                  const Icon(Icons.arrow_right, size: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub['title']),
                        if (hasSubmitted)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (proof.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        content: Image.memory(base64Decode(proof)),
                                      ),
                                    );
                                  },
                                  child: Text('Tap to view image proof', style: TextStyle(decoration: TextDecoration.underline)),
                                ),
                              if (comment.isNotEmpty)
                                Text('Comment: $comment', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (isAssignedToMe && (status == 'Pending' || status == 'Rejected'))
                    ElevatedButton(
                      onPressed: () => showSubmitDialog(task, i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueText,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Finish'),
                    )
                  else if (!isAssignedToMe && status == 'under_review' && !alreadyVoted)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up, color: Colors.green),
                          onPressed: () => setState(() {
                            db.voteOnSubtask(widget.projectName, task['id'], i, currentUsername, true, '');
                            if (allOthersVoted) db.finalizeVotes(widget.projectName, task['id'], i);
                            tasks = db.getTasksForProject(widget.projectName);
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down, color: Colors.red),
                          onPressed: () => setState(() {
                            db.voteOnSubtask(widget.projectName, task['id'], i, currentUsername, false, '');
                            if (allOthersVoted) db.finalizeVotes(widget.projectName, task['id'], i);
                            tasks = db.getTasksForProject(widget.projectName);
                          }),
                        ),
                      ],
                    )
                  else
                    Text(
                      status == 'under_review'
                          ? 'Under review. Please wait.'
                          : status,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: status == 'Approved'
                            ? Colors.green
                            : status == 'Rejected'
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                ],
              );
            }),
            if (canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    await showEditSubtasksDialog(task);
                    setState(() {
                      tasks = db.getTasksForProject(widget.projectName);
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Subtasks"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> showEditSubtasksDialog(Map<String, dynamic> task) async {
    final newSubtaskController = TextEditingController();
    final rawSubtasks = task['subtasks'];
    final subtasks = rawSubtasks is List
        ? List<Map<String, dynamic>>.from(rawSubtasks)
        : <Map<String, dynamic>>[];

    final controllers = subtasks.map((s) => TextEditingController(text: s['title'])).toList();

    return showDialog<bool>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text("Edit Subtasks"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    for (int i = 0; i < controllers.length; i++)
                      Row(
                        children: [
                          Expanded(child: TextField(controller: controllers[i])),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() {
                              controllers.removeAt(i);
                            }),
                          ),
                        ],
                      ),
              TextField(
                controller: newSubtaskController,
                decoration: const InputDecoration(hintText: "New subtask"),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Subtask"),
                onPressed: () {
                  if (newSubtaskController.text.trim().isNotEmpty) {
                    setState(() {
                      controllers.add(TextEditingController(text: newSubtaskController.text.trim()));
                      newSubtaskController.clear();
                    });
                  }
                },
              ),
            ],
          ),
        ),
              actions: [
                TextButton(
                  onPressed: () {
                    final updatedTitles = controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                    final rawExisting = task['subtasks'];
                    final existingSubtasks = rawExisting is List
                        ? List<Map<String, dynamic>>.from(rawExisting)
                        : <Map<String, dynamic>>[];

                    final newSubtasks = updatedTitles.map((title) {
                      final match = existingSubtasks
                          .firstWhere(
                            (sub) => sub['title'].toString().trim().toLowerCase() == title.trim().toLowerCase(),
                            orElse: () => <String, dynamic>{},
                          );

                      if (match.isNotEmpty) {
                        return {
                          'title': title,
                          'status': match['status'],
                          'proof': match['proof'],
                          'comment': match['comment'],
                          'votes': (match['votes'] is Map)
                              ? Map.fromEntries(
                                  (match['votes'] as Map).entries.where((e) =>
                                      e.key is String &&
                                      (e.value is bool || e.value == true || e.value == false)).map(
                                    (e) => MapEntry(e.key as String, e.value == true),
                                  ),
                                )
                              : <String, bool>{},
                        };
                      } else {
                        return {
                          'title': title,
                          'status': 'Pending',
                          'proof': '',
                          'comment': '',
                          'votes': {},
                        };
                      }
                    }).toList();

                    db.replaceSubtasks(widget.projectName, task['id'], newSubtasks);

                    Navigator.pop(context, true); 
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          );
        },
      ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final completion = getCompletionPercentage();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.blueText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.projectName,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                'Course: ${widget.courseName}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Completion: ${completion.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tasks:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (['admin', 'officer', 'teacher'].contains(role))
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignLeaderScreen(projectName: widget.projectName),
                      ),
                    ).then((_) => setState(() {
                          project = db.getAllProjects().firstWhere((p) => p['name'] == widget.projectName);
                          isLeader = project['leader'] == currentUsername;
                        }));
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text("Assign Project Leader", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
                ),
              ),
            if (['admin', 'officer', 'teacher'].contains(role) || isLeader)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignTaskScreen(projectName: widget.projectName),
                      ),
                    ).then((_) {
                      setState(() {
                        tasks = db.getTasksForProject(widget.projectName);
                      });
                    });
                  },
                  icon: const Icon(Icons.assignment, color: Colors.white),
                  label: const Text("Assign Task", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('No tasks assigned yet.'))
                  : ListView(
                      children: tasks.map(buildTaskCard).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
