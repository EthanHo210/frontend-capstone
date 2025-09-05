import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'app_colors.dart';
import 'assign_leader_screen.dart';
import 'assign_task_screen.dart';
import 'course_teams_screen.dart';
import 'mock_database.dart';
import 'route_observer.dart';

class ProjectStatusScreen extends StatefulWidget {
  final String projectName;
  final String courseName;

  /// If true, render content-only (no Scaffold/AppBar) so it can live inside
  /// MainDashboard/DashboardScaffold without duplicating chrome.
  final bool embedded;

  /// Called by embedded flow to open the in-dashboard Assign Task screen.
  final VoidCallback? onOpenAssignTaskEmbedded;

  /// Called by embedded flow to open the in-dashboard Assign Leader screen.
  final VoidCallback? onOpenAssignLeaderEmbedded;

  /// NEW: bump this number from a parent (e.g., after Assign Task/Leader)
  /// to force this screen to reload project state without a relogin.
  final int refreshTick;

  const ProjectStatusScreen({
    super.key,
    required this.projectName,
    required this.courseName,
    this.embedded = false,
    this.onOpenAssignTaskEmbedded,
    this.onOpenAssignLeaderEmbedded,
    this.refreshTick = 0,
  });

  @override
  State<ProjectStatusScreen> createState() => _ProjectStatusScreenState();
}

class _ProjectStatusScreenState extends State<ProjectStatusScreen>
    with RouteAware {
  final db = MockDatabase();
  Map<String, dynamic> project = {};
  late String currentUsername;
  late String currentFullName;
  late String role;
  bool isLeader = false;
  List<Map<String, dynamic>> tasks = [];
  List<String> projectMembers = [];

  StreamSubscription<Map<String, dynamic>>? _notifSub;

  // ===== NEW: lock helper (Completed/Overdue can no longer submit) =====
  bool get _projectLocked {
    try {
      final deadline = (project['deadline'] ?? '').toString();
      if (deadline.isEmpty) return false;
      final completion = getCompletionPercentage().round();
      final status = db.calculateStatus(deadline, completion);
      return status == 'Completed' || status == 'Overdue';
    } catch (_) {
      return false;
    }
  }
  // =====================================================================

  @override
  void initState() {
    super.initState();

    currentUsername = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ??
        (db.currentLoggedInUser ?? '');
    currentFullName = db.getFullNameByUsername(currentUsername) ?? currentUsername;

    // Stay consistent with your other screens: getUserRole() is called with the email/currentLoggedInUser
    role = db.getUserRole(db.currentLoggedInUser ?? '');

    _loadProjectState();

    // Listen for notifications; if current user gets something, refresh.
    _notifSub = db.notificationStream.listen((event) {
      if (!mounted) return;
      final u = (event['username'] as String?) ?? '';
      if (u == currentUsername) {
        _loadProjectState();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProjectStatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if:
    // 1) parent bumps refreshTick, or
    // 2) we navigated to a different project (edge case).
    if (oldWidget.refreshTick != widget.refreshTick ||
        oldWidget.projectName != widget.projectName) {
      _loadProjectState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when coming back from AssignTask / AssignLeader (standalone flow),
    // or any pushed route that returns to this screen.
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

  void showVoteCommentDialog(
      Map<String, dynamic> task, int subtaskIndex, bool vote) async {
    final controllerWhy = TextEditingController();
    final controllerBetter = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          vote ? 'Agree with submission' : 'Disagree with submission',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controllerWhy,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'Why do you ${vote ? "agree" : "disagree"} with this?',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            TextField(
              controller: controllerBetter,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                labelText: 'What could be done better?',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final feedback =
                  '${controllerWhy.text.trim()}\nSuggestions: ${controllerBetter.text.trim()}';

              db.voteOnSubtask(widget.projectName, task['id'], subtaskIndex,
                  currentUsername, vote, feedback);

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
              if (allEligibleVoted) {
                db.finalizeVotes(widget.projectName, task['id'], subtaskIndex);
              }

              setState(() {
                tasks = db.getTasksForProject(widget.projectName);
              });
              Navigator.pop(context);
            },
            child: Text('Submit', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void showSubmitDialog(Map<String, dynamic> task, int subtaskIndex) async {
    // ===== NEW: hard guard in case of stale UI =====
    if (_projectLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This project is locked (Completed/Overdue). Submissions are closed.'),
        ),
      );
      return;
    }
    // ==============================================

    String comment = '';
    Uint8List? imageBytes;
    final picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Confirm Finish',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    setModalState(() => imageBytes = bytes);
                  }
                },
                icon: const Icon(Icons.image),
                label: Text("Upload Proof Image", style: GoogleFonts.poppins()),
              ),
              if (imageBytes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Image.memory(imageBytes!, height: 100),
                ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Comment',
                  labelStyle: GoogleFonts.poppins(),
                ),
                style: GoogleFonts.poppins(),
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
                      title: Text("Submit Subtask",
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      content: Text(
                        "Are you sure you want to submit this subtask for review?",
                        style: GoogleFonts.poppins(),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text("Cancel", style: GoogleFonts.poppins())),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text("Yes", style: GoogleFonts.poppins())),
                      ],
                    ),
                  );

                  if (confirmSubmit == true) {
                    final proofPath =
                        imageBytes != null ? base64Encode(imageBytes!) : '';
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
              child: Text('Submit', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTaskCard(Map<String, dynamic> task) {
    final subtasks = (task['subtasks'] ?? []) as List<dynamic>;

    final assignedToRaw = task['assignedTo']?.toString() ?? '';
    final assignedFullName = db.getFullNameByUsername(assignedToRaw) ??
        db.getFullNameByEmail(assignedToRaw) ??
        assignedToRaw;

    final canEdit =
        ['admin', 'officer', 'teacher'].contains(role) || isLeader;

    final isProjectMember = projectMembers.contains(currentUsername);
    final bool currentIsAdminOrOfficer =
        role == 'admin' || role == 'officer';

    final localPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.blueText;
    final localSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    // ===== NEW: cache lock for this render =====
    final locked = _projectLocked;
    // ==========================================

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
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: localPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Assigned to: $assignedFullName',
                style: GoogleFonts.poppins(color: localPrimary)),
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
                        Text((sub['title'] ?? '').toString(),
                            style: GoogleFonts.poppins(color: localPrimary)),
                        if (hasSubmitted)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (proof.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    try {
                                      final img = base64Decode(proof);
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          content: Image.memory(img),
                                        ),
                                      );
                                    } catch (_) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Unable to display image proof.'),
                                      ));
                                    }
                                  },
                                  child: Text(
                                    'Tap to view image proof',
                                    style: GoogleFonts.poppins(
                                      decoration: TextDecoration.underline,
                                      color: localSecondary,
                                    ),
                                  ),
                                ),

                              if (comment.isNotEmpty)
                                Text('Comment: $comment',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: localSecondary)),

                              // comments visible to voter OR assignee OR any project member (non-admin/officer)
                              if (sub['comments'] != null &&
                                  sub['comments'] is Map)
                                ...((Map<String, dynamic>.from(
                                        sub['comments'] as Map))
                                    .entries
                                    .map((entry) {
                                  final voter = entry.key.toString();
                                  final feedback =
                                      entry.value?.toString() ?? '';
                                  final allowedToView =
                                      (voter == currentUsername) ||
                                          isAssignedToMe ||
                                          (projectMembers
                                                  .contains(currentUsername) &&
                                              !currentIsAdminOrOfficer);

                                  if (!allowedToView) {
                                    return const SizedBox.shrink();
                                  }

                                  final fullName =
                                      db.getFullNameByUsername(voter) ??
                                          voter;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$fullName's comments",
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: localSecondary),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          onPressed: () async {
                                            if (voter ==
                                                currentUsername) {
                                              // allow edit of own comment
                                              String q1 = '';
                                              String q2 = '';
                                              final parts = feedback.split(
                                                  RegExp(
                                                      r'Suggestions:\s*',
                                                      caseSensitive:
                                                          false));
                                              if (parts.isNotEmpty) {
                                                q1 = parts[0].trim();
                                              }
                                              if (parts.length > 1) {
                                                q2 = parts[1].trim();
                                              }

                                              final q1Controller =
                                                  TextEditingController(
                                                      text: q1);
                                              final q2Controller =
                                                  TextEditingController(
                                                      text: q2);

                                              final newComment =
                                                  await showDialog<String>(
                                                context: context,
                                                builder: (ctx) =>
                                                    AlertDialog(
                                                  title: Text(
                                                    'Your comment (edit)',
                                                    style:
                                                        GoogleFonts.poppins(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  ),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              q1Controller,
                                                          maxLines: 3,
                                                          style:
                                                              GoogleFonts
                                                                  .poppins(),
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'Why do you agree/disagree with this?',
                                                            hintText:
                                                                'Enter your reasoning...',
                                                            labelStyle:
                                                                GoogleFonts
                                                                    .poppins(),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        TextField(
                                                          controller:
                                                              q2Controller,
                                                          maxLines: 3,
                                                          style:
                                                              GoogleFonts
                                                                  .poppins(),
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'What could be done better?',
                                                            hintText:
                                                                'Enter your suggestions...',
                                                            labelStyle:
                                                                GoogleFonts
                                                                    .poppins(),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, null),
                                                        child: Text('Cancel',
                                                            style:
                                                                GoogleFonts
                                                                    .poppins())),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        '${q1Controller.text.trim()}\nSuggestions: ${q2Controller.text.trim()}',
                                                      ),
                                                      child: Text('Save',
                                                          style: GoogleFonts
                                                              .poppins()),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (newComment != null) {
                                                final currentVoteMap =
                                                    (sub['votes'] is Map)
                                                        ? Map<String,
                                                                dynamic>.from(
                                                            sub['votes']
                                                                as Map)
                                                        : <String,
                                                            dynamic>{};
                                                final currentVoteValue =
                                                    (currentVoteMap[
                                                            currentUsername] ==
                                                        true);

                                                db.voteOnSubtask(
                                                  widget.projectName,
                                                  task['id'],
                                                  i,
                                                  currentUsername,
                                                  currentVoteValue,
                                                  newComment,
                                                );

                                                setState(() {
                                                  tasks = db
                                                      .getTasksForProject(
                                                          widget
                                                              .projectName);
                                                });
                                              }
                                            } else {
                                              // read-only view
                                              String q1 = '';
                                              String q2 = '';
                                              final parts = feedback.split(
                                                  RegExp(
                                                      r'Suggestions:\s*',
                                                      caseSensitive:
                                                          false));
                                              if (parts.isNotEmpty) {
                                                q1 = parts[0].trim();
                                              }
                                              if (parts.length > 1) {
                                                q2 = parts[1].trim();
                                              }

                                              await showDialog<void>(
                                                context: context,
                                                builder: (ctx) =>
                                                    AlertDialog(
                                                  title: Text(
                                                    "$fullName's comment",
                                                    style:
                                                        GoogleFonts.poppins(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                  ),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Why do you agree/disagree with this?',
                                                          style:
                                                              GoogleFonts
                                                                  .poppins(),
                                                        ),
                                                        Text(
                                                            q1.isNotEmpty
                                                                ? q1
                                                                : 'No answer',
                                                            style:
                                                                GoogleFonts
                                                                    .poppins()),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          'What could be done better?',
                                                          style:
                                                              GoogleFonts
                                                                  .poppins(),
                                                        ),
                                                        Text(
                                                            q2.isNotEmpty
                                                                ? q2
                                                                : 'No suggestions',
                                                            style:
                                                                GoogleFonts
                                                                    .poppins()),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx),
                                                        child: Text('Close',
                                                            style:
                                                                GoogleFonts
                                                                    .poppins())),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: Text('View Comment',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12)),
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
                  ] else if (isAssignedToMe &&
                      (status == 'Pending' || status == 'Rejected') &&
                      !locked) ...[ // ===== NEW: block submit button when locked =====
                    ElevatedButton(
                      onPressed: () => showSubmitDialog(task, i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueText,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Confirm Finish',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    ),
                  ] else ...[
                    Text(
                      status == 'under_review'
                          ? 'Under review. Please wait.'
                          : status.toString(),
                      style: GoogleFonts.poppins(
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
                  label: Text("Edit Subtasks", style: GoogleFonts.poppins()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> showEditSubtasksDialog(Map<String, dynamic> task) async {
    final newSubtaskController = TextEditingController();

    // Build controllers for existing subtasks (by title only — updateSubtasks will preserve data)
    final rawSubtasks = task['subtasks'];
    final existing = rawSubtasks is List
        ? List<Map<String, dynamic>>.from(rawSubtasks)
        : <Map<String, dynamic>>[];
    final controllers = existing
        .map((s) => TextEditingController(text: (s['title'] ?? '').toString()))
        .toList();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text("Edit Subtasks",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < controllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controllers[i],
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: 'Subtask',
                              hintStyle: GoogleFonts.poppins(),
                            ),
                          ),
                        ),
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
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: "New subtask",
                      hintStyle: GoogleFonts.poppins(),
                    ),
                    onSubmitted: (_) {
                      final t = newSubtaskController.text.trim();
                      if (t.isNotEmpty) {
                        setState(() {
                          controllers.add(TextEditingController(text: t));
                          newSubtaskController.clear();
                        });
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text("Add Subtask", style: GoogleFonts.poppins()),
                    onPressed: () {
                      final t = newSubtaskController.text.trim();
                      if (t.isNotEmpty) {
                        setState(() {
                          controllers.add(TextEditingController(text: t));
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
                  final updatedTitles = controllers
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  // 🔔 This method preserves existing subtasks and
                  // notifies the assignee if *new* titles were added.
                  db.updateSubtasks(widget.projectName, task['id'], updatedTitles);

                  Navigator.pop(context, true);
                },
                child: Text("Save", style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  Widget _buildContent(BuildContext context) {
    final bool useEmbedded = widget.embedded;

    // If the project wasn't found, fail gracefully.
    if (project.isEmpty) {
      final errorColor = Theme.of(context).colorScheme.error;
      return Center(
        child: Text(
          'Project "${widget.projectName}" was not found.',
          style: GoogleFonts.poppins(
              color: errorColor, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    final completion = getCompletionPercentage();
    final textColor = Theme.of(context).textTheme.titleLarge?.color ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        AppColors.blueText;
    final secondaryColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return SafeArea(
      top: !useEmbedded,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.projectName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
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
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('Tasks:',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
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
                          builder: (_) =>
                              AssignLeaderScreen(projectName: widget.projectName),
                        ),
                      ).then((_) => setState(_loadProjectState));
                    }
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: Text("Assign Project Leader",
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
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
                          builder: (_) =>
                              AssignTaskScreen(projectName: widget.projectName),
                        ),
                      ).then((_) => setState(() {
                            tasks =
                                db.getTasksForProject(widget.projectName);
                          }));
                    }
                  },
                  icon: const Icon(Icons.assignment, color: Colors.white),
                  label: Text("Assign Task",
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text('No tasks assigned yet.',
                          style: GoogleFonts.poppins(color: secondaryColor)))
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

    final bool useEmbedded = widget.embedded;

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
                  builder: (_) =>
                      CourseTeamsScreen(selectedCourse: widget.courseName),
                ),
              );
            }
          },
        ),
        title: Text(
          'Project Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color ??
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.blueText,
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
