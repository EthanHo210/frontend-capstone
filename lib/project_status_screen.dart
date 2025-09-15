// project_status_screen.dart
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

  /// Bump this number from a parent to force a refresh.
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

  // ===== Helpers for dialogs & images =====

  /// Prevents Material 3 surface tint from whitening dialogs on web.
  Widget _wrapDialog(Widget child) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        dialogTheme: theme.dialogTheme.copyWith(
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      child: child,
    );
  }

  /// Safe base64 decode; returns null on failure.
  Uint8List? _safeB64(String s) {
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  Widget _brokenThumb({double size = 90}) => Container(
        height: size,
        width: size,
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      );

  // ===== Lock helper (Completed/Overdue can no longer submit) =====
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
  // ================================================================

  @override
  void initState() {
    super.initState();

    currentUsername = db.getUsernameByEmail(db.currentLoggedInUser ?? '') ??
        (db.currentLoggedInUser ?? '');
    currentFullName =
        db.getFullNameByUsername(currentUsername) ?? currentUsername;

    // Stay consistent with other screens: getUserRole() accepts email/username
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
      final approvedCount =
          subtasks.where((s) => s['status'] == 'Approved').length;
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
      builder: (context) => _wrapDialog(
        AlertDialog(
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
                  labelText:
                      'Why do you ${vote ? "agree" : "disagree"} with this?',
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

                final subtasks = (task['subtasks'] ?? []) as List<dynamic>;
                final sub = subtasks[subtaskIndex];
                final votes = Map<String, bool>.from(sub['votes'] ?? {});

                // eligible voters: project members excluding assignee + excluding admin/officer roles
                final eligibleVoters = projectMembers.where((m) {
                  if (m == task['assignedTo']) return false;
                  final r = db.getUserRole(m);
                  return !(r == 'admin' || r == 'officer');
                }).toList();

                final allEligibleVoted = eligibleVoters.isEmpty
                    ? true
                    : eligibleVoters.every((m) => votes.containsKey(m));
                if (allEligibleVoted) {
                  db.finalizeVotes(
                      widget.projectName, task['id'], subtaskIndex);
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
      ),
    );
  }

  /// Allow attaching up to 5 images (stored as JSON array-of-base64 in `proof`)
  /// Allow attaching up to 5 images (stored as JSON array-of-base64 in `proof`)
  void showSubmitDialog(Map<String, dynamic> task, int subtaskIndex) async {
    if (_projectLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This project is locked (Completed/Overdue). Submissions are closed.'),
        ),
      );
      return;
    }

    String comment = '';
    final picker = ImagePicker();
    List<Uint8List> imageBytesList = [];

    await showDialog(
      context: context,
      builder: (context) => _wrapDialog(
        StatefulBuilder(
          builder: (context, setModalState) {
            final canSubmit = imageBytesList.isNotEmpty || comment.trim().isNotEmpty;

            Future<void> _pickMore() async {
              final picked = await picker.pickMultiImage();
              if (picked.isEmpty) return;

              final newly = <Uint8List>[];
              for (final x in picked) {
                if (imageBytesList.length + newly.length >= 5) break;
                newly.add(await x.readAsBytes());
              }
              setModalState(() {
                imageBytesList = [...imageBytesList, ...newly].take(5).toList();
              });
              if (imageBytesList.length >= 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You can upload up to 5 images.')),
                );
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Confirm Finish',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _pickMore,
                        icon: const Icon(Icons.image),
                        label: Text('Upload Proof Image(s)', style: GoogleFonts.poppins()),
                      ),

                      if (imageBytesList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('${imageBytesList.length}/5 selected',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        const SizedBox(height: 6),

                        // Give the scroller a finite size so no intrinsic measurement is needed.
                        SizedBox(
                          height: 90,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (int i = 0; i < imageBytesList.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            imageBytesList[i],
                                            height: 90,
                                            width: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _brokenThumb(),
                                          ),
                                        ),
                                        Positioned(
                                          right: -12,
                                          top: -12,
                                          child: IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                                            tooltip: 'Remove',
                                            onPressed: () => setModalState(() => imageBytesList.removeAt(i)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Comment',
                          labelStyle: GoogleFonts.poppins(),
                        ),
                        style: GoogleFonts.poppins(),
                        onChanged: (val) => setModalState(() => comment = val),
                      ),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: canSubmit
                              ? () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => _wrapDialog(
                                      AlertDialog(
                                        title: Text('Submit Subtask', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                        content: Text('Are you sure you want to submit this subtask for review?',
                                            style: GoogleFonts.poppins()),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins())),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes', style: GoogleFonts.poppins())),
                                        ],
                                      ),
                                    ),
                                  );
                                  if (confirm != true) return;

                                  final proofsBase64 = imageBytesList.map((b) => base64Encode(b)).toList();
                                  final proofPayload = jsonEncode(proofsBase64);

                                  db.submitSubtaskProof(
                                    widget.projectName,
                                    task['id'],
                                    subtaskIndex,
                                    currentUsername,
                                    comment,
                                    proofPayload,
                                  );

                                  if (mounted) {
                                    setState(() => tasks = db.getTasksForProject(widget.projectName));
                                    Navigator.pop(context); // close the submit dialog
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueText),
                          child: Text('Submit', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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

    final canEdit = ['admin', 'officer', 'teacher'].contains(role) || isLeader;

    final isProjectMember = projectMembers.contains(currentUsername);
    final bool currentIsAdminOrOfficer =
        role == 'admin' || role == 'officer';

    final localPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.blueText;
    final localSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    final locked = _projectLocked;

    final allApproved = subtasks.isNotEmpty &&
        subtasks.every((s) => s['status'] == 'Approved');

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
                  allApproved ? Icons.check_circle : Icons.pending,
                  color: allApproved ? Colors.green : Colors.orange,
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
                style:
                    GoogleFonts.poppins(color: localPrimary)),
            const SizedBox(height: 8),

            ...List.generate(subtasks.length, (i) {
              final sub = subtasks[i];

              // --- proofs: handle single base64 or JSON list-of-base64 ---
              final proofLegacy = sub['proof'] ?? '';
              final proofsField = sub['proofs'] ?? proofLegacy;

              List<String> proofList = [];
              if (proofsField is List) {
                proofList = proofsField
                    .map((e) => e.toString())
                    .where((s) => s.isNotEmpty)
                    .toList();
              } else if (proofsField is String &&
                  proofsField.isNotEmpty) {
                try {
                  final parsed = jsonDecode(proofsField);
                  if (parsed is List) {
                    proofList = parsed
                        .map((e) => e.toString())
                        .where((s) => s.isNotEmpty)
                        .toList();
                  } else {
                    proofList = [proofsField];
                  }
                } catch (_) {
                  proofList = [proofsField];
                }
              }

              final comment = sub['comment'] ?? '';
              final votes =
                  Map<String, bool>.from(sub['votes'] ?? {});
              final status = sub['status'];
              final alreadyVoted =
                  votes.containsKey(currentUsername);
              final isAssignedToMe =
                  task['assignedTo'] == currentUsername;
              final hasSubmitted = proofList.isNotEmpty ||
                  (comment is String && comment.isNotEmpty);

              // voting rules
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
                            style: GoogleFonts.poppins(
                                color: localPrimary)),

                        if (hasSubmitted) ...[
                          if (proofList.isNotEmpty)
                            SizedBox(
                              height: 70,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: proofList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (_, idx) {
                                  final bytes =
                                      _safeB64(proofList[idx]);
                                  if (bytes == null) {
                                    return _brokenThumb(size: 70);
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      final full =
                                          _safeB64(proofList[idx]);
                                      if (full == null) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Unable to display image proof.'),
                                          ),
                                        );
                                        return;
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (_) => _wrapDialog(
                                          Dialog(
                                            insetPadding:
                                                const EdgeInsets
                                                    .all(16),
                                            clipBehavior:
                                                Clip.antiAlias,
                                            child: ConstrainedBox(
                                              constraints:
                                                  BoxConstraints(
                                                maxWidth: MediaQuery.of(
                                                            context)
                                                        .size
                                                        .width *
                                                    0.9,
                                                maxHeight: MediaQuery.of(
                                                            context)
                                                        .size
                                                        .height *
                                                    0.8,
                                                minWidth: 280,
                                                minHeight: 180,
                                              ),
                                              child:
                                                  InteractiveViewer(
                                                child: Image.memory(
                                                  full,
                                                  fit: BoxFit
                                                      .contain,
                                                  errorBuilder: (_,
                                                          __,
                                                          ___) =>
                                                      const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets
                                                              .all(
                                                                  24),
                                                      child: Icon(Icons
                                                          .broken_image),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      child: Image.memory(
                                        bytes,
                                        height: 70,
                                        width: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                _brokenThumb(
                                                    size: 70),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          if (comment is String &&
                              comment.isNotEmpty)
                            Text('Comment: $comment',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: localSecondary)),
                        ],

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
                                    (projectMembers.contains(
                                            currentUsername) &&
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
                                        final parts =
                                            feedback.split(
                                          RegExp(
                                              r'Suggestions:\s*',
                                              caseSensitive:
                                                  false),
                                        );
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
                                            await showDialog<
                                                String>(
                                          context: context,
                                          builder: (ctx) =>
                                              _wrapDialog(
                                            AlertDialog(
                                              title: Text(
                                                'Your comment (edit)',
                                                style: GoogleFonts
                                                    .poppins(
                                                        fontWeight:
                                                            FontWeight
                                                                .w600),
                                              ),
                                              content:
                                                  SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize
                                                          .min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          q1Controller,
                                                      maxLines:
                                                          3,
                                                      style: GoogleFonts
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
                                                        height:
                                                            8),
                                                    TextField(
                                                      controller:
                                                          q2Controller,
                                                      maxLines:
                                                          3,
                                                      style: GoogleFonts
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
                                                          ctx,
                                                          null),
                                                  child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts
                                                          .poppins()),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                    ctx,
                                                    '${q1Controller.text.trim()}\nSuggestions: ${q2Controller.text.trim()}',
                                                  ),
                                                  child: Text(
                                                      'Save',
                                                      style: GoogleFonts
                                                          .poppins()),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );

                                        if (newComment !=
                                            null) {
                                          final currentVoteMap =
                                              (sub['votes']
                                                      is Map)
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
                                        final parts =
                                            feedback.split(
                                          RegExp(
                                              r'Suggestions:\s*',
                                              caseSensitive:
                                                  false),
                                        );
                                        if (parts.isNotEmpty) {
                                          q1 = parts[0].trim();
                                        }
                                        if (parts.length > 1) {
                                          q2 = parts[1].trim();
                                        }

                                        await showDialog<void>(
                                          context: context,
                                          builder: (ctx) =>
                                              _wrapDialog(
                                            AlertDialog(
                                              title: Text(
                                                "$fullName's comment",
                                                style: GoogleFonts
                                                    .poppins(
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
                                                      style: GoogleFonts
                                                          .poppins(),
                                                    ),
                                                    Text(
                                                      q1.isNotEmpty
                                                          ? q1
                                                          : 'No answer',
                                                      style: GoogleFonts
                                                          .poppins(),
                                                    ),
                                                    const SizedBox(
                                                        height:
                                                            8),
                                                    Text(
                                                      'What could be done better?',
                                                      style: GoogleFonts
                                                          .poppins(),
                                                    ),
                                                    Text(
                                                      q2.isNotEmpty
                                                          ? q2
                                                          : 'No suggestions',
                                                      style: GoogleFonts
                                                          .poppins(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx),
                                                  child: Text(
                                                      'Close',
                                                      style: GoogleFonts
                                                          .poppins()),
                                                ),
                                              ],
                                            ),
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
                  ),

                  if (canVote) ...[
                    IconButton(
                      icon: const Icon(Icons.thumb_up,
                          color: Colors.green),
                      onPressed: () =>
                          showVoteCommentDialog(task, i, true),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.thumb_down, color: Colors.red),
                      onPressed: () =>
                          showVoteCommentDialog(task, i, false),
                    ),
                  ] else if (isAssignedToMe &&
                      (status == 'Pending' || status == 'Rejected') &&
                      !locked) ...[
                    // Assignee sees explicit "Rejected" message + action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (status == 'Rejected')
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Rejected — please revise and resubmit',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () => showSubmitDialog(task, i),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueText,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Confirm Finish',
                              style: GoogleFonts.poppins(
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Everyone else: only reveal final status to the assignee.
                    Builder(
                      builder: (_) {
                        String msg = '';
                        Color color = localSecondary;

                        if (isAssignedToMe) {
                          if (status == 'under_review') {
                            msg = 'Under review. Please wait.';
                            color = Colors.orange;
                          } else if (status == 'Approved') {
                            msg = 'Approved';
                            color = Colors.green;
                          } else if (status == 'Rejected') {
                            msg = 'Rejected';
                            color = Colors.red;
                          } else {
                            msg = status.toString();
                          }
                        } else {
                          if (status == 'under_review') {
                            msg = 'Under review. Please wait.';
                            color = Colors.orange;
                          } else if (status == 'Approved' ||
                              status == 'Rejected') {
                            // Hide the exact outcome from non-assignees
                            msg = 'Awaiting assignee.';
                            color = localSecondary;
                          } else {
                            msg = '';
                          }
                        }

                        if (msg.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          msg,
                          style: GoogleFonts.poppins(
                            fontStyle: FontStyle.italic,
                            color: color,
                          ),
                        );
                      },
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
                  label: Text("Edit Subtasks",
                      style: GoogleFonts.poppins()),
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
    final existing = rawSubtasks is List
        ? List<Map<String, dynamic>>.from(rawSubtasks)
        : <Map<String, dynamic>>[];
    final controllers = existing
        .map((s) => TextEditingController(text: (s['title'] ?? '').toString()))
        .toList();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return _wrapDialog(
          StatefulBuilder(
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
                            controllers
                                .add(TextEditingController(text: t));
                            newSubtaskController.clear();
                          });
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text("Add Subtask",
                          style: GoogleFonts.poppins()),
                      onPressed: () {
                        final t = newSubtaskController.text.trim();
                        if (t.isNotEmpty) {
                          setState(() {
                            controllers
                                .add(TextEditingController(text: t));
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

                    // Preserves existing subtasks data; notifies assignee for new titles.
                    db.updateSubtasks(
                        widget.projectName, task['id'], updatedTitles);

                    Navigator.pop(context, true);
                  },
                  child:
                      Text("Save", style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'On-track':
        return Colors.green;
      case 'Delayed':
        return Colors.orange;
      case 'Crisis':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      case 'Overdue':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildContent(BuildContext context) {
    final bool useEmbedded = widget.embedded;

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

    final deadline = (project['deadline'] ?? '').toString();
    final status = db.calculateStatus(deadline, completion.round());

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
                style: GoogleFonts.poppins(
                    fontSize: 14, color: secondaryColor),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
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
                    if (useEmbedded &&
                        widget.onOpenAssignLeaderEmbedded != null) {
                      widget.onOpenAssignLeaderEmbedded!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignLeaderScreen(
                              projectName: widget.projectName),
                        ),
                      ).then((_) => setState(_loadProjectState));
                    }
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: Text("Assign Project Leader",
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueText),
                ),
              ),

            if (['admin', 'officer', 'teacher'].contains(role) ||
                isLeader)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (useEmbedded &&
                        widget.onOpenAssignTaskEmbedded != null) {
                      widget.onOpenAssignTaskEmbedded!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignTaskScreen(
                              projectName: widget.projectName),
                        ),
                      ).then((_) => setState(() {
                            tasks = db.getTasksForProject(
                                widget.projectName);
                          }));
                    }
                  },
                  icon:
                      const Icon(Icons.assignment, color: Colors.white),
                  label: Text("Assign Task",
                      style: GoogleFonts.poppins(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text('No tasks assigned yet.',
                          style: GoogleFonts.poppins(
                              color: secondaryColor)))
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
      return content;
    }

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
                  builder: (_) => CourseTeamsScreen(
                      selectedCourse: widget.courseName),
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
        iconTheme:
            IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: content,
    );
  }
}
