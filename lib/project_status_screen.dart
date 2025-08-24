import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_database.dart';
import 'app_colors.dart';
import 'assign_leader_screen.dart';
import 'assign_task_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'course_teams_screen.dart';

class ProjectStatusScreen extends StatefulWidget {
  final String projectName;
  final String courseName;

  /// If true, render content-only (no Scaffold/AppBar) so it can live inside
  /// MainDashboard/DashboardScaffold without duplicating chrome.
  final bool embedded;

  final VoidCallback? onOpenAssignTaskEmbedded;
  final VoidCallback? onOpenAssignLeaderEmbedded; // <-- callback for embedded Assign Leader

  const ProjectStatusScreen({
    super.key,
    required this.projectName,
    required this.courseName,
    this.embedded = false,
    this.onOpenAssignTaskEmbedded,
    this.onOpenAssignLeaderEmbedded,
  });

  @override
  State<ProjectStatusScreen> createState() => _ProjectStatusScreenState();
}

class _ProjectStatusScreenState extends State<ProjectStatusScreen> {
  final db = MockDatabase();
  Map<String, dynamic> project = {};
  late String currentUsername;
  late String currentFullName;
  late String role;
  bool isLeader = false;
  List<Map<String, dynamic>> tasks = [];
  List<String> projectMembers = [];

  @override
  void initState() {
    super.initState();
    currentUsername =
        db.getUsernameByEmail(db.currentLoggedInUser ?? '') ?? (db.currentLoggedInUser ?? '');
    currentFullName = db.getFullNameByUsername(currentUsername) ?? currentUsername;

    // Stay consistent with your other screens: getUserRole() is called with the email/currentLoggedInUser
    role = db.getUserRole(db.currentLoggedInUser ?? '');

    _loadProjectState();
  }

  void _loadProjectState() {
    final all = db.getAllProjects();
    project = all.firstWhere(
      (p) => (p['name']?.toString() ?? '') == widget.projectName,
      orElse: () => <String, dynamic>{},
    );

    isLeader = db.getProjectLeader(widget.projectName) == currentUsername;
    tasks = db.getTasksForProject(widget.projectName);
    projectMembers = db.getProjectMembers(widget.projectName);
    if (mounted) setState(() {});
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

  void showVoteCommentDialog(Map<String, dynamic> task, int subtaskIndex, bool vote) async {
    final controllerWhy = TextEditingController();
    final controllerBetter = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vote ? 'Agree with submission' : 'Disagree with submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerWhy,
              decoration: InputDecoration(
                labelText: 'Why do you ${vote ? "agree" : "disagree"} with this?',
              ),
            ),
            TextField(
              controller: controllerBetter,
              decoration: const InputDecoration(labelText: 'What could be done better?'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final feedback =
                  '${controllerWhy.text.trim()}\nSuggestions: ${controllerBetter.text.trim()}';
              db.voteOnSubtask(widget.projectName, task['id'], subtaskIndex, currentUsername, vote, feedback);

              final subtasks = task['subtasks'] as List<dynamic>;
              final sub = subtasks[subtaskIndex];
              final votes = Map<String, bool>.from(sub['votes'] ?? {});

              // eligible voters: project members excluding assignee + excluding admin/officer roles
              final eligibleVoters = projectMembers.where((m) {
                if (m == task['assignedTo']) return false;
                final r = db.getUserRole(m);
                return !(r == 'admin' || r == 'officer');
              }).toList();

              final allEligibleVoted =
                  eligibleVoters.isEmpty ? true : eligibleVoters.every((m) => votes.containsKey(m));
              if (allEligibleVoted) db.finalizeVotes(widget.projectName, task['id'], subtaskIndex);

              setState(() {
                tasks = db.getTasksForProject(widget.projectName);
              });
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
                    setModalState(() => imageBytes = bytes);
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
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
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

    final assignedToRaw = task['assignedTo']?.toString() ?? '';
    final assignedFullName = db.getFullNameByUsername(assignedToRaw)
        ?? db.getFullNameByEmail(assignedToRaw)
        ?? assignedToRaw;

    final canEdit = ['admin', 'officer', 'teacher'].contains(role) || isLeader;

    final isProjectMember = projectMembers.contains(currentUsername);
    final bool currentIsAdminOrOfficer = role == 'admin' || role == 'officer';

    final localPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.blueText;
    final localSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

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
                  subtasks.every((s) => s['status'] == 'Approved')
                      ? Icons.check_circle
                      : Icons.pending,
                  color: subtasks.every((s) => s['status'] == 'Approved')
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  task['title'] ?? 'Unnamed Task',
                  style: TextStyle(fontWeight: FontWeight.bold, color: localPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Assigned to: $assignedFullName', style: TextStyle(color: localPrimary)),
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

              // voting rules: only project members (not assignee), not admin/officer, and not already voted
              final canVote = !isAssignedToMe &&
                  status == 'under_review' &&
                  !alreadyVoted &&
                  isProjectMember &&
                  !currentIsAdminOrOfficer;

              return Row(
                children: [
                  const Icon(Icons.arrow_right, size: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub['title'], style: TextStyle(color: localPrimary)),
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
                                  child: Text(
                                    'Tap to view image proof',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: localSecondary,
                                    ),
                                  ),
                                ),
                              if (comment.isNotEmpty)
                                Text('Comment: $comment',
                                    style: TextStyle(fontSize: 12, color: localSecondary)),

                              // comments visible to voter OR assignee OR any project member (non-admin/officer)
                              if (sub['comments'] != null && sub['comments'] is Map)
                                ...((Map<String, dynamic>.from(sub['comments'] as Map)).entries.map((entry) {
                                  final voter = entry.key.toString();
                                  final feedback = entry.value?.toString() ?? '';
                                  final allowedToView = (voter == currentUsername) ||
                                      isAssignedToMe ||
                                      (projectMembers.contains(currentUsername) && !currentIsAdminOrOfficer);

                                  if (!allowedToView) return const SizedBox.shrink();

                                  final fullName = db.getFullNameByUsername(voter) ?? voter;

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$fullName's comments",
                                          style: TextStyle(fontSize: 12, color: localSecondary),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          onPressed: () async {
                                            if (voter == currentUsername) {
                                              // allow edit of own comment
                                              String q1 = '';
                                              String q2 = '';
                                              final parts = feedback.split(RegExp(r'Suggestions:\s*', caseSensitive: false));
                                              if (parts.isNotEmpty) q1 = parts[0].trim();
                                              if (parts.length > 1) q2 = parts[1].trim();

                                              final q1Controller = TextEditingController(text: q1);
                                              final q2Controller = TextEditingController(text: q2);

                                              final newComment = await showDialog<String>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Your comment (edit)'),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      TextField(
                                                        controller: q1Controller,
                                                        maxLines: 3,
                                                        decoration: const InputDecoration(
                                                          labelText: 'Why do you agree/disagree with this?',
                                                          hintText: 'Enter your reasoning...',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      TextField(
                                                        controller: q2Controller,
                                                        maxLines: 3,
                                                        decoration: const InputDecoration(
                                                          labelText: 'What could be done better?',
                                                          hintText: 'Enter your suggestions...',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(
                                                        ctx,
                                                        '${q1Controller.text.trim()}\nSuggestions: ${q2Controller.text.trim()}',
                                                      ),
                                                      child: const Text('Save'),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (newComment != null) {
                                                final currentVoteMap = (sub['votes'] is Map)
                                                    ? Map<String, dynamic>.from(sub['votes'] as Map)
                                                    : <String, dynamic>{};
                                                final currentVoteValue = (currentVoteMap[currentUsername] == true);

                                                db.voteOnSubtask(
                                                  widget.projectName,
                                                  task['id'],
                                                  i,
                                                  currentUsername,
                                                  currentVoteValue,
                                                  newComment,
                                                );

                                                setState(() {
                                                  tasks = db.getTasksForProject(widget.projectName);
                                                });
                                              }
                                            } else {
                                              // read-only view
                                              String q1 = '';
                                              String q2 = '';
                                              final parts = feedback.split(RegExp(r'Suggestions:\s*', caseSensitive: false));
                                              if (parts.isNotEmpty) q1 = parts[0].trim();
                                              if (parts.length > 1) q2 = parts[1].trim();

                                              await showDialog<void>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text("$fullName's comment"),
                                                  content: SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Why do you agree/disagree with this?'),
                                                        Text(q1.isNotEmpty ? q1 : 'No answer'),
                                                        const SizedBox(height: 8),
                                                        const Text('What could be done better?'),
                                                        Text(q2.isNotEmpty ? q2 : 'No suggestions'),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text('View Comment', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()),
                            ],
                          ),
                      ],
                    ),
                  ),

                  if (canVote) ...[
                    IconButton(
                      icon: const Icon(Icons.thumb_up, color: Colors.green),
                      onPressed: () => showVoteCommentDialog(task, i, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down, color: Colors.red),
                      onPressed: () => showVoteCommentDialog(task, i, false),
                    ),
                  ] else if (isAssignedToMe && (status == 'Pending' || status == 'Rejected')) ...[
                    ElevatedButton(
                      onPressed: () => showSubmitDialog(task, i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueText,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm Finish'),
                    ),
                  ] else ...[
                    Text(
                      status == 'under_review' ? 'Under review. Please wait.' : status,
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
                  final updatedTitles =
                      controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

                  final rawExisting = task['subtasks'];
                  final existingSubtasks = rawExisting is List
                      ? List<Map<String, dynamic>>.from(rawExisting)
                      : <Map<String, dynamic>>[];

                  final newSubtasks = updatedTitles.map((title) {
                    // Find existing subtask by title (case-insensitive)
                    final match = existingSubtasks.firstWhere(
                      (sub) => sub['title'].toString().trim().toLowerCase() ==
                          title.trim().toLowerCase(),
                      orElse: () => <String, dynamic>{},
                    );

                    // Preserve existing id if available, otherwise create one
                    final id = (match['id'] != null && match['id'].toString().isNotEmpty)
                        ? match['id'].toString()
                        : DateTime.now().microsecondsSinceEpoch.toString();

                    // Preserve fields when present, otherwise default
                    final status = (match['status'] != null) ? match['status'] : 'Pending';
                    final proof = (match['proof'] != null) ? match['proof'] : '';
                    final comment = (match['comment'] != null) ? match['comment'] : '';

                    // Normalize votes to Map<String,bool>
                    Map<String, bool> votesMap = {};
                    if (match['votes'] is Map) {
                      (match['votes'] as Map).forEach((k, v) {
                        if (k != null) votesMap[k.toString()] = (v == true);
                      });
                    }

                    // Preserve voter comments map
                    Map<String, String> commentsMap = {};
                    if (match['comments'] is Map) {
                      (match['comments'] as Map).forEach((k, v) {
                        if (k != null) commentsMap[k.toString()] = v?.toString() ?? '';
                      });
                    }

                    return {
                      'id': id,
                      'title': title,
                      'status': status,
                      'proof': proof,
                      'comment': comment,
                      'votes': votesMap,
                      'comments': commentsMap,
                    };
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

  Widget _buildContent(BuildContext context) {
    // NEW: auto-embed if we’re already inside a Scaffold (e.g. DashboardScaffold)
    final bool useEmbedded = widget.embedded || Scaffold.maybeOf(context) != null;
    
    // If the project wasn't found, fail gracefully.
    if (project.isEmpty) {
      final errorColor = Theme.of(context).colorScheme.error;
      return Center(
        child: Text(
          'Project "${widget.projectName}" was not found.',
          style: GoogleFonts.poppins(color: errorColor, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    final completion = getCompletionPercentage();
    final textColor = Theme.of(context).textTheme.titleLarge?.color
        ?? Theme.of(context).textTheme.bodyLarge?.color
        ?? AppColors.blueText;
    final secondaryColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return SafeArea(
      top: !useEmbedded,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // No local header row in embedded mode (DashboardScaffold provides it).
            // When standalone, the Scaffold's AppBar will show the title.

            Center(
              child: Text(
                widget.projectName,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            Center(
              child: Text(
                'Course: ${widget.courseName}',
                style: GoogleFonts.poppins(fontSize: 14, color: secondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Completion: ${completion.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            const SizedBox(height: 20),

            Text('Tasks:', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),

            if (['admin', 'officer', 'teacher'].contains(role))
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (useEmbedded && widget.onOpenAssignLeaderEmbedded != null) {
                      // open the embedded Assign Leader page in MainDashboard
                      widget.onOpenAssignLeaderEmbedded!();
                    } else {
                      // fallback to standalone route (kept for backward compatibility)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignLeaderScreen(projectName: widget.projectName),
                        ),
                      ).then((_) => setState(_loadProjectState));
                    }
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
                    if (useEmbedded && widget.onOpenAssignTaskEmbedded != null) {
                      // open the embedded Assign Task page in MainDashboard
                      widget.onOpenAssignTaskEmbedded!();
                    } else {
                      // fallback to standalone route (kept for backward compatibility)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignTaskScreen(projectName: widget.projectName),
                        ),
                      ).then((_) => setState(() {
                            tasks = db.getTasksForProject(widget.projectName);
                          }));
                    }
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

            const SizedBox(height: 8),

            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text('No tasks assigned yet.', style: TextStyle(color: secondaryColor)))
                  : ListView(children: tasks.map(buildTaskCard).toList()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    // NEW: auto-embed if there’s an ancestor Scaffold
    final bool useEmbedded = widget.embedded || Scaffold.maybeOf(context) != null;

    if (useEmbedded) {
      // Content-only: parent chrome (AppBar/BottomNav) is provided by DashboardScaffold.
      return content;
    }

    // Standalone route: provide our own Scaffold + AppBar (backwards compatible).
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseTeamsScreen(selectedCourse: widget.courseName),
                ),
              );
            }
          },
        ),
        title: Text(
          'Project Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color
                ?? Theme.of(context).textTheme.bodyMedium?.color
                ?? AppColors.blueText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: content,
    );
  }
}
