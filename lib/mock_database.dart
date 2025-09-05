// mock_database.dart
import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal() {
    // Default notifications: enabled for all seeded users
    for (final u in _users) {
      _notifEnabled[u['username'] as String] = true;
    }
  }

  final Uuid _uuid = Uuid();

  // -----------------------------
  // USERS (seed)
  // -----------------------------
  final List<Map<String, dynamic>> _users = [
    {
      'id': Uuid().v4(),
      'username': 'testuser1',
      'email': 'ethanho200017@yahoo.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
      'fullName': 'Ethan Ho',
    },
    {
      'id': Uuid().v4(),
      'username': 'testuser2',
      'email': 'user2@example.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
      'fullName': 'Brian Tran',
    },
    {
      'id': Uuid().v4(),
      'username': 'testuser3',
      'email': 'user3@example.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
      'fullName': 'Cynthia Le',
    },
    {
      'id': Uuid().v4(),
      'username': 'teacher1',
      'email': 'teacher@example.com',
      'password': sha256.convert(utf8.encode('teacherpass')).toString(),
      'role': 'teacher',
      'fullName': 'David Hoang',
    },
    {
      'id': Uuid().v4(),
      'username': 'admin',
      'email': 'admin@example.com',
      'password': sha256.convert(utf8.encode('adminpass')).toString(),
      'role': 'admin',
      'fullName': '',
    },
    {
      'id': Uuid().v4(),
      'username': 'officer1',
      'email': 'officer@example.com',
      'password': sha256.convert(utf8.encode('officerpass')).toString(),
      'role': 'officer',
      'fullName': 'Felix Vo',
    },
  ];

  // -----------------------------
  // NOTIFICATIONS
  // -----------------------------
  final Map<String, List<Map<String, dynamic>>> _notificationsByUser = {};
  final Map<String, bool> _notifEnabled = {};
  final StreamController<Map<String, dynamic>> _notifStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notifStream.stream;

  List<Map<String, dynamic>> getNotifications(String username) {
    final list =
        List<Map<String, dynamic>>.from(_notificationsByUser[username] ?? const []);
    list.sort(
      (a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String),
    );
    return list;
  }

  int getUnreadNotificationCount(String username) =>
      (_notificationsByUser[username] ?? const [])
          .where((n) => n['read'] == false)
          .length;

  void markAllNotificationsRead(String username) {
    final list = _notificationsByUser[username];
    if (list == null) return;
    for (final n in list) n['read'] = true;
  }

  void markNotificationRead(String username, String id) {
    final list = _notificationsByUser[username];
    if (list == null) return;
    for (final n in list) {
      if (n['id'] == id) {
        n['read'] = true;
        break;
      }
    }
  }

  bool isNotificationsEnabled(String username) => _notifEnabled[username] ?? true;
  void setNotificationsEnabled(String username, bool enabled) {
    _notifEnabled[username] = enabled;
  }

  void _pushNotification(
    String username, {
    required String title,
    required String body,
    required String type, // 'project_created'|'leader_assigned'|'task_assigned'|'proof_uploaded'|'proof_result'
    String? payload,
  }) {
    if (!isNotificationsEnabled(username)) return;

    final n = <String, dynamic>{
      'id': _uuid.v4(),
      'title': title,
      'body': body,
      'type': type,
      'payload': payload,
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    final list = _notificationsByUser.putIfAbsent(username, () => []);
    list.add(n);

    _notifStream.add({'username': username, 'notification': n});
  }

  // -----------------------------
  // COURSES (RICH MODEL) + BACK-COMPAT
  // -----------------------------
  /// Back-compat list of course names (legacy callers still use this).
  final List<String> _courses = [];

  /// New rich course store: id -> course record
  /// { id, name, semester, campus, lecturers<List<String>>, students<List<String>>, description, createdAt }
  final Map<String, Map<String, dynamic>> _coursesById = {};

  /// Create a rich course and keep legacy names in sync.
  /// Create (or upsert) a rich course and keep legacy names in sync.
  /// If a course with the same (name, semester, campus) already exists,
  /// we merge lecturers/students and return its id instead of creating a duplicate.
  String createCourse({
    required String name,
    String semester = 'N/A',
    String campus = 'N/A',
    List<String>? lecturers,
    List<String>? students,
    String description = '',
  }) {
    final normName = name.trim().toLowerCase();
    final normSem  = semester.trim().toLowerCase();
    final normCamp = campus.trim().toLowerCase();

    // look for existing by (name, semester, campus)
    final existing = _coursesById.values.firstWhereOrNull((c) {
      final n = (c['name'] ?? '').toString().trim().toLowerCase();
      final s = (c['semester'] ?? 'n/a').toString().trim().toLowerCase();
      final k = (c['campus'] ?? 'n/a').toString().trim().toLowerCase();
      return n == normName && s == normSem && k == normCamp;
    });

    if (existing != null) {
      // merge lecturers/students (no dups)
      final id = existing['id'].toString();
      final curLect = ((existing['lecturers'] as List?) ?? const [])
          .map((e) => e.toString()).toSet();
      final curStud = ((existing['students']  as List?) ?? const [])
          .map((e) => e.toString()).toSet();

      if (lecturers != null) curLect.addAll(lecturers.map((e) => e.toString()));
      if (students  != null) curStud.addAll(students.map((e) => e.toString()));

      existing['lecturers'] = curLect.toList();
      existing['students']  = curStud.toList();
      if (description.isNotEmpty) existing['description'] = description;

      if (!_courses.contains(name)) _courses.add(name);
      return id;
    }

    // create new
    final id = _uuid.v4();
    _coursesById[id] = {
      'id': id,
      'name': name,
      'semester': semester,
      'campus': campus,
      'lecturers': List<String>.from(lecturers ?? const []),
      'students': List<String>.from(students ?? const []),
      'description': description,
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (!_courses.contains(name)) _courses.add(name);
    return id;
  }

  /// Update fields of a rich course. Handles name change propagation.
  bool updateCourse(
    String courseId, {
    String? name,
    String? semester,
    String? campus,
    List<String>? lecturers,
    List<String>? students,
    String? description,
  }) {
    final c = _coursesById[courseId];
    if (c == null) return false;

    final oldName = c['name']?.toString() ?? 'N/A';

    if (name != null && name.trim().isNotEmpty) c['name'] = name.trim();
    if (semester != null) c['semester'] = semester;
    if (campus != null) c['campus'] = campus;
    if (lecturers != null) c['lecturers'] = List<String>.from(lecturers);
    if (students != null) c['students'] = List<String>.from(students);
    if (description != null) c['description'] = description;

    // Keep legacy names list in sync and propagate rename to projects/_userProjects
    final newName = c['name']?.toString() ?? oldName;
    if (newName != oldName) {
      if (_courses.contains(oldName)) {
        _courses[_courses.indexOf(oldName)] = newName;
      } else if (!_courses.contains(newName)) {
        _courses.add(newName);
      }
      // propagate to projects
      for (final p in _projects) {
        if ((p['course'] ?? '') == oldName || (p['courseId'] ?? '') == courseId) {
          p['course'] = newName;
          p['courseId'] = courseId;
        }
      }
      // and to user project snapshots
      for (final key in _userProjects.keys) {
        if ((_userProjects[key]?['course'] ?? '') == oldName) {
          _userProjects[key]!['course'] = newName;
        }
      }
    }
    return true;
  }

  /// Delete rich course by ID (projects and snapshots updated)
  bool deleteCourseById(String courseId) {
    final c = _coursesById.remove(courseId);
    if (c == null) return false;

    final name = (c['name'] ?? '').toString();

    // remove from legacy names
    _courses.remove(name);

    // delete all projects tied (by name OR id)
    final projectsToDelete = _projects
        .where((p) => (p['course'] ?? '') == name || (p['courseId'] ?? '') == courseId)
        .map((p) => (p['name'] ?? '').toString())
        .where((x) => x.isNotEmpty)
        .toList();
    for (final pn in projectsToDelete) {
      deleteProject(pn);
    }

    // clean user snapshots
    for (final key in _userProjects.keys.toList()) {
      if ((_userProjects[key]?['course'] ?? '') == name) {
        final currentProjectName = _userProjects[key]?['project'] ?? '';
        final isDeletedProject = projectsToDelete.contains(currentProjectName);
        _userProjects[key]!['course'] = 'N/A';
        if (isDeletedProject) {
          _userProjects[key]!['project'] = 'N/A';
          _userProjects[key]!['contribution'] = '0%';
          _userProjects[key]!['rank'] = 'Unranked';
          _userProjects[key]!['deadline'] = '';
        }
      }
    }
    return true;
  }

  /// Convenience: find by name (case-insensitive)
  Map<String, dynamic>? getCourseByName(String name) {
    final needle = name.trim().toLowerCase();
    return _coursesById.values
        .firstWhereOrNull((c) => (c['name'] ?? '').toString().toLowerCase() == needle);
  }

  Map<String, dynamic>? getCourseById(String id) => _coursesById[id];

  /// Rich list for UIs that show extra metadata (de-duplicated by name+semester+campus).
  List<Map<String, dynamic>> getAllCoursesRich() {
    final Map<String, Map<String, dynamic>> byKey = {};
    for (final c in _coursesById.values) {
      final key =
          '${(c['name'] ?? '').toString().trim().toLowerCase()}|'
          '${(c['semester'] ?? '').toString().trim().toLowerCase()}|'
          '${(c['campus'] ?? '').toString().trim().toLowerCase()}';

      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = Map<String, dynamic>.from(c);
      } else {
        // keep the newest one
        final a = DateTime.tryParse((existing['createdAt'] ?? '').toString()) ?? DateTime(1970);
        final b = DateTime.tryParse((c['createdAt'] ?? '').toString()) ?? DateTime(1970);
        if (b.isAfter(a)) byKey[key] = Map<String, dynamic>.from(c);
      }
    }
    return byKey.values.toList();
  }


  /// Add/remove lecturers (admin UI)
  bool addLecturerToCourse(String courseIdentifier, String username) {
    final course = _resolveCourse(courseIdentifier);
    if (course == null) return false;
    // Optional: require the target user to be a teacher
    if (!isTeacher(username)) return false;
    final list = (course['lecturers'] as List).cast<String>();
    if (!list.contains(username)) list.add(username);
    return true;
    // (you can emit notifications here if desired)
  }

  bool removeLecturerFromCourse(String courseIdentifier, String username) {
    final course = _resolveCourse(courseIdentifier);
    if (course == null) return false;
    final list = (course['lecturers'] as List).cast<String>();
    list.remove(username);
    return true;
  }

  /// Add/remove students (admin UI)
  bool addStudentToCourse(String courseIdentifier, String username) {
    final course = _resolveCourse(courseIdentifier);
    if (course == null) return false;
    // Optional: require a 'user' role
    if (!isStudent(username)) return false;
    final list = (course['students'] as List).cast<String>();
    if (!list.contains(username)) list.add(username);
    return true;
  }

  bool removeStudentFromCourse(String courseIdentifier, String username) {
    final course = _resolveCourse(courseIdentifier);
    if (course == null) return false;
    final list = (course['students'] as List).cast<String>();
    list.remove(username);
    return true;
  }

  List<String> getLecturersForCourse(String courseIdentifier) {
    final c = _resolveCourse(courseIdentifier);
    if (c == null) return const [];
    return List<String>.from(c['lecturers'] ?? const []);
  }

  List<String> getStudentsForCourse(String courseIdentifier) {
    final c = _resolveCourse(courseIdentifier);
    if (c == null) return const [];
    return List<String>.from(c['students'] ?? const []);
  }

  Map<String, dynamic>? _resolveCourse(String courseIdentifier) {
    // accept either id or name
    final byId = _coursesById[courseIdentifier];
    if (byId != null) return byId;
    return getCourseByName(courseIdentifier);
  }

  // -----------------------------
  // PROJECTS / TASKS
  // -----------------------------
  final Map<String, Map<String, String>> _userProjects = {};
  final List<Map<String, dynamic>> _projects = [];
  String? _currentLoggedInUser;
  final String _adminPin = '1234';

  final Map<String, List<Map<String, dynamic>>> _projectTasks = {};
  final Map<String, String> _projectLeaders = {};

  // --- LOCK / STATUS HELPERS ---
  double projectCompletionPercent(String projectName) {
    final tasks = _projectTasks[projectName] ?? const [];
    if (tasks.isEmpty) return 0.0;

    int confirmed = 0;
    for (final t in tasks) {
      final subtasks = (t['subtasks'] as List?) ?? const [];
      if (subtasks.isEmpty) continue;
      final approved = subtasks.where((s) => s['status'] == 'Approved').length;
      if (approved == subtasks.length) confirmed++;
    }
    return (confirmed / tasks.length) * 100.0;
  }

  /// Live status based on deadline + computed completion
  String currentProjectStatus(String projectName) {
    final proj = _projects.firstWhere(
      (p) => (p['name'] ?? '') == projectName,
      orElse: () => <String, dynamic>{},
    );
    if (proj.isEmpty) return 'Unknown';
    final deadline = (proj['deadline'] ?? '').toString();
    final completion = projectCompletionPercent(projectName).round();
    return calculateStatus(deadline, completion);
  }

  /// Completed or Overdue projects are "locked" (no more submissions)
  bool isProjectLocked(String projectName) {
    final status = currentProjectStatus(projectName);
    return status == 'Completed' || status == 'Overdue';
  }


  void assignLeader(String projectName, String username) {
    _projectLeaders[projectName] = username;
    for (var project in _projects) {
      if (project['name'] == projectName) {
        project['leader'] = username;
        break;
      }
    }
    _pushNotification(
      username,
      title: 'You are the leader',
      body: 'You have been assigned as leader for "$projectName".',
      type: 'leader_assigned',
      payload: projectName,
    );
  }

  String? getProjectLeader(String projectName) => _projectLeaders[projectName];

  void addTaskToProject(
    String projectName, {
    required String title,
    required String assignedTo,
    List<String>? subtasks,
  }) {
    final task = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'assignedTo': assignedTo,
      'subtasks': subtasks
              ?.map((s) => {
                    'id': DateTime.now().microsecondsSinceEpoch.toString(),
                    'title': s,
                    'status': 'Pending',
                    'votes': <String, bool>{},
                    'comments': <String, String>{},
                    'proof': '',
                    'submittedBy': null,
                  })
              .toList() ??
          [],
      'status': 'Pending',
      'proof': '',
      'votes': <String, bool>{},
      'comments': <String, String>{},
      'submittedBy': null,
      'confirmed': false,
    };
    _projectTasks.putIfAbsent(projectName, () => []).add(task);

    _pushNotification(
      assignedTo,
      title: 'Task assigned',
      body: '"$title" in "$projectName" has been assigned to you.',
      type: 'task_assigned',
      payload: projectName,
    );
  }

  List<Map<String, dynamic>> getTasksForProject(String projectName) =>
      _projectTasks[projectName] ?? [];

  void submitTaskProof(String projectName, String taskId, int subtaskIndex,  String proofText, String user, String comment, String imageUrl) {
    if (isProjectLocked(projectName)){
      return;
    }

    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhereOrNull((t) => t['id'] == taskId);
    if (task == null) return;

    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtaskIndex < 0 || subtaskIndex >= subtasks.length) return;

    final subtask = subtasks[subtaskIndex];
    subtask['proof'] = imageUrl;
    subtask['comment'] = comment;
    subtask['status'] = 'under_review';
    subtask['votes'] = <String, bool>{};
    subtask['comments'] = <String, String>{};
    subtask['submittedBy'] = user;

    if (task.isNotEmpty) {
      task['proof'] = proofText;
      task['status'] = 'awaiting_review';
      task['votes'] = <String, bool>{};
      task['comments'] = <String, String>{};

      final allMembers =
          _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {})['members']
                  as List? ??
              [];
      final assignee = task['assignedTo'];
      final reviewers = allMembers.where((m) => m != assignee).cast<String>().toList();

      for (final r in reviewers) {
        _pushNotification(
          r,
          title: 'Task proof submitted',
          body: 'Proof submitted for "${task['title']}" in "$projectName". Please review.',
          type: 'proof_uploaded',
          payload: taskId,
        );
      }
    }
  }

  void voteOnTask(
    String projectName,
    String taskId,
    String voter,
    bool agree,
    String comment,
  ) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;
    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isNotEmpty && task['status'] == 'awaiting_review') {
      (task['votes'] as Map<String, bool>)[voter] = agree;
      (task['comments'] as Map<String, String>)[voter] = comment;

      final allMembers =
          _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {})['members']
                  as List? ??
              [];

      final votes = task['votes'] as Map<String, bool>;
      if (votes.length >= (allMembers.length / 2).ceil()) {
        final approvals = votes.values.where((v) => v).length;
        if (approvals > allMembers.length / 2) {
          task['status'] = 'Approved';
        } else {
          task['status'] = 'Rejected';
        }
      }
    }
  }

  void voteOnSubtask(
    String projectName,
    String taskId,
    int subtaskIndex,
    String voter,
    bool agree,
    String comment,
  ) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isEmpty) return;

    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtaskIndex < 0 || subtaskIndex >= subtasks.length) return;

    final subtask = subtasks[subtaskIndex];

    subtask['votes'] = (subtask['votes'] is Map)
        ? Map<String, bool>.from(subtask['votes'] as Map)
        : <String, bool>{};
    subtask['comments'] = (subtask['comments'] is Map)
        ? Map<String, String>.from(subtask['comments'] as Map)
        : <String, String>{};

    (subtask['votes'] as Map<String, bool>)[voter] = agree;
    (subtask['comments'] as Map<String, String>)[voter] = comment;

    final allMembers =
        _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {})['members']
                as List? ??
            [];

    final assignee = task['assignedTo'];
    final eligibleVoters = allMembers
        .where((m) => m != assignee)
        .where((m) {
          final r = getUserRole(m);
          return r != 'admin' && r != 'officer';
        })
        .cast<String>()
        .toList();

    final votes = subtask['votes'] as Map<String, bool>;

    if (votes.keys.toSet().containsAll(eligibleVoters)) {
      final approvals =
          votes.entries.where((e) => eligibleVoters.contains(e.key) && e.value).length;
      subtask['status'] = approvals > (eligibleVoters.length / 2) ? 'Approved' : 'Rejected';
    }

    if (subtask['comments'] == null || subtask['comments'] is! Map<String, String>) {
      subtask['comments'] = <String, String>{};
    }
  }

  double calculateMainTaskProgress(Map<String, dynamic> task) {
    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtasks.isEmpty) return 0;

    final approvedCount = subtasks.where((s) => s['status'] == 'Approved').length;
    return (approvedCount / subtasks.length) * 100;
  }

  void updateSubtasks(String projectName, String taskId, List<String> updatedTitles) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhere(
      (t) => t['id'] == taskId,
      orElse: () => <String, dynamic>{},
    );
    if (task.isEmpty) return;

    final existing =
        (task['subtasks'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

    final updatedSubtasks = <Map<String, dynamic>>[];
    final addedTitles = <String>[];

    for (final raw in updatedTitles) {
      final t = raw.trim();
      if (t.isEmpty) continue;

      final match = existing.firstWhere(
        (s) => (s['title'] ?? '').toString().trim().toLowerCase() == t.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (match.isNotEmpty) {
        updatedSubtasks.add(match);
      } else {
        updatedSubtasks.add({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'title': t,
          'status': 'Pending',
          'votes': <String, bool>{},
          'comments': <String, String>{},
          'proof': '',
          'submittedBy': null,
        });
        addedTitles.add(t);
      }
    }

    task['subtasks'] = updatedSubtasks;

    if (addedTitles.isNotEmpty) {
      final assignedTo = (task['assignedTo'] ?? '').toString();
      final course = (_projects.firstWhere(
        (p) => p['name'] == projectName,
        orElse: () => {},
      )['course'] ??
          'N/A')
          .toString();

      _pushNotification(
        assignedTo,
        title: 'New subtasks assigned',
        body: 'You have been given tasks in $course - $projectName. Please open the app to check.',
        type: 'task_assigned',
        payload: projectName,
      );
    }
  }

  void submitSubtaskProof(
    String projectName,
    String taskId,
    int subtaskIndex,
    String user,
    String comment,
    String imageUrl,
  ) {
    final proj = _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {});
    final status = (proj['status'] ?? '').toString();
    if (status == 'Completed' || status == 'Overdue') {
      return; // or throw if you prefer surfacing an error
    }

    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhereOrNull((t) => t['id'] == taskId);
    if (task == null) return;

    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtaskIndex < 0 || subtaskIndex >= subtasks.length) return;

    final subtask = subtasks[subtaskIndex];
    subtask['proof'] = imageUrl;
    subtask['comment'] = comment;
    subtask['status'] = 'under_review';
    subtask['votes'] = <String, bool>{};
    subtask['comments'] = <String, String>{};
    subtask['submittedBy'] = user;

    final allMembers =
        _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {})['members']
                as List? ??
            [];
    final assignee = task['assignedTo'];
    final reviewers = allMembers
        .where((m) => m != user && m != assignee)
        .where((m) {
          final r = getUserRole(m);
          return r != 'admin' && r != 'officer';
        })
        .cast<String>()
        .toList();

    final subtaskTitle = (subtask['title'] ?? '').toString();
    for (final r in reviewers) {
      _pushNotification(
        r,
        title: 'Proof uploaded',
        body: '$user submitted proof for "$subtaskTitle" in "$projectName".',
        type: 'proof_uploaded',
        payload: taskId,
      );
    }
  }

  void finalizeVotes(String projectName, String taskId, int subtaskIndex) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isEmpty) return;

    final subtasks = task['subtasks'] as List;
    final subtask = subtasks[subtaskIndex];

    final votes = subtask['votes'] as Map<String, bool>;
    int approvals = votes.values.where((v) => v == true).length;
    int rejections = votes.values.where((v) => v == false).length;

    if (approvals > rejections) {
      subtask['status'] = 'Approved';
    } else {
      subtask['status'] = 'Rejected';
      subtask['votes'] = {}; // allow retry
    }

    final submitter = (subtask['submittedBy'] ?? '').toString();
    if (submitter.isNotEmpty) {
      final subtaskTitle = (subtask['title'] ?? '').toString();
      _pushNotification(
        submitter,
        title: subtask['status'] == 'Approved' ? 'Proof approved' : 'Proof rejected',
        body:
            '"$subtaskTitle" in "$projectName" was ${subtask['status'].toString().toLowerCase()}.',
        type: 'proof_result',
        payload: taskId,
      );
    }
  }

  void replaceSubtasks(
    String projectName,
    String taskId,
    List<Map<String, dynamic>> newSubtasks,
  ) {
    final tasks = _projectTasks[projectName];
    if (tasks != null) {
      final index = tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        tasks[index]['subtasks'] = newSubtasks;
      }
    }
  }

  List<String> getProjectMembers(String projectName) {
    final project = _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {});
    return List<String>.from(project['members'] ?? []);
  }

  // -----------------------------
  // CREATION PERMISSION + addProject
  // -----------------------------

  bool canCreateProject([String? userId]) {
    final id = userId ?? (_currentLoggedInUser ?? '');
    final role = getUserRole(id);
    // Allow officers to open/create as well (UI already does this)
    return role == 'teacher' || role == 'admin' || role == 'officer';
  }

  // ⬇️ NEW: helpers to check for duplicate projects
  bool _sameMemberSet(List<String> a, List<String> b) {
    final sa = a.map((e) => e.trim().toLowerCase()).toSet();
    final sb = b.map((e) => e.trim().toLowerCase()).toSet();
    return sa.length == sb.length && sa.difference(sb).isEmpty;
  }

  bool _isDuplicateProject({
    required String name,
    required String? courseId,
    required String courseName,
    required String startDate,
    required String deadline,
    required List<String> members,
  }) {
    final nameKey = name.trim().toLowerCase();
    final courseKey = (courseId?.trim().toLowerCase().isNotEmpty == true)
        ? courseId!.trim().toLowerCase()
        : courseName.trim().toLowerCase();

    for (final p in _projects) {
      final pName = (p['name'] ?? '').toString().trim().toLowerCase();
      final pCourseId = (p['courseId'] ?? '').toString().trim().toLowerCase();
      final pCourseName = (p['course'] ?? '').toString().trim().toLowerCase();
      final pCourseKey = pCourseId.isNotEmpty ? pCourseId : pCourseName;

      final pStart = (p['startDate'] ?? '').toString();
      final pDeadline = (p['deadline'] ?? '').toString();
      final pMembers = (p['members'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

      if (pName == nameKey &&
          pCourseKey == courseKey &&
          pStart == startDate &&
          pDeadline == deadline &&
          _sameMemberSet(pMembers, members)) {
        return true;
      }
    }
    return false;
  }
  // ⬆️ NEW

  void addProject(Map<String, String> projectData) {
    // Role gate (now includes officers)
    if (!canCreateProject()) {
      throw StateError('Only lecturers, admins, or officers can create projects.');
    }

    // Accept either course name or courseId (or both). Persist both if possible.
    final incomingCourseName = (projectData['course'] ?? '').trim();
    final incomingCourseId = (projectData['courseId'] ?? '').trim();
    String resolvedCourseName = incomingCourseName.isNotEmpty ? incomingCourseName : 'N/A';
    String? resolvedCourseId =
        incomingCourseId.isNotEmpty ? incomingCourseId : null;

    if (resolvedCourseId != null) {
      final c = getCourseById(resolvedCourseId);
      if (c != null) resolvedCourseName = (c['name'] ?? 'N/A').toString();
    } else if (resolvedCourseName != 'N/A') {
      final c = getCourseByName(resolvedCourseName);
      if (c != null) resolvedCourseId = c['id']?.toString();
    }

    // Parse members from CSV first (used by the policy check and below)
    final members = projectData['members']!
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Server-side policy: if the creator is NOT a teacher, at least one lecturer must be in members.
    final creator = getUsernameByEmail(_currentLoggedInUser ?? '') ?? (_currentLoggedInUser ?? '');
    final creatorRole = getUserRole(creator);
    if (creatorRole != 'teacher') {
      final hasLecturer = members.any((u) => isTeacher(u));
      if (!hasLecturer) {
        throw StateError('Non-lecturer creators must include at least one lecturer in the project.');
      }
    }

    // ⬇️ NEW: duplicate guard BEFORE adding
    if (_isDuplicateProject(
      name: projectData['name']!.trim(),
      courseId: resolvedCourseId,
      courseName: resolvedCourseName,
      startDate: projectData['startDate']!.trim(),
      deadline: projectData['deadline']!.trim(),
      members: members,
    )) {
      throw StateError('A project with the same name, course, dates, and members already exists.');
    }
    // ⬆️ NEW

    final status = calculateStatus(projectData['deadline']!, 0);

    final createdBy =
        getUsernameByEmail(_currentLoggedInUser ?? '') ?? (_currentLoggedInUser ?? '');

    _projects.add({
      'id': _uuid.v4(),
      'name': projectData['name']!,
      'members': members,
      'startDate': projectData['startDate']!,
      'deadline': projectData['deadline']!,
      'status': status,
      'course': resolvedCourseName,
      'courseId': resolvedCourseId, // keep both

      'createdAt': DateTime.now().toIso8601String(),
      'createdBy': createdBy,
    });

    final username =
        getUsernameByEmail(_currentLoggedInUser ?? '') ?? _currentLoggedInUser;
    if (username != null) {
      _userProjects[username] = {
        'project': projectData['name']!,
        'contribution': '0%',
        'rank': status,
        'course': resolvedCourseName,
        'deadline': projectData['deadline'] ?? '',
      };
    }

    for (final m in members) {
      _pushNotification(
        m,
        title: 'New project',
        body: '"${projectData['name']}" ($resolvedCourseName) has been created and you were added.',
        type: 'project_created',
        payload: projectData['name'],
      );
    }
  }

  List<Map<String, dynamic>> getAllProjects() => _projects;

  List<Map<String, dynamic>> getProjectsForCurrentUser() {
    final username = getUsernameByEmail(_currentLoggedInUser ?? '') ?? '';
    return _projects.where((project) {
      final members = (project['members'] as List).cast<String>();
      return members.contains(username);
    }).toList();
  }

  Map<String, String>? getProjectInfoForUser(String usernameOrEmail) {
    String username = usernameOrEmail;
    for (var user in _users) {
      if (user['email'] == usernameOrEmail) {
        username = user['username'];
        break;
      }
    }
    return _userProjects[username];
  }

  Map<String, dynamic>? getUserByUsername(String username) {
    return _users.firstWhere(
      (user) => user['username'] == username,
      orElse: () => {},
    );
  }

  void setProjectInfoForUser(String usernameOrEmail, Map<String, dynamic> projectInfo) {
    String? username = usernameOrEmail;
    for (var user in _users) {
      if (user['email'] == usernameOrEmail) {
        username = user['username'];
        break;
      }
    }

    if (username != null) {
      _userProjects[username] = {
        'project': projectInfo['name']?.toString() ?? 'N/A',
        'contribution': projectInfo['completion']?.toString() ?? '0%',
        'rank': projectInfo['status']?.toString() ?? 'Unranked',
        'course': projectInfo['course']?.toString() ?? 'N/A',
        'deadline': projectInfo['deadline']?.toString() ?? '',
      };
    }
  }

  String calculateStatus(String deadlineStr, int completionPercent) {
    final deadline = DateTime.tryParse(deadlineStr);
    if (deadline == null) return 'Unknown';

    final today = DateTime.now();
    final daysLeft = deadline.difference(today).inDays;

    if (completionPercent >= 100) return 'Completed';
    if (daysLeft <= 0 && completionPercent < 100) return 'Overdue';
    if (daysLeft <= 7 && completionPercent < 80) return 'Crisis';
    if (daysLeft <= 14 && completionPercent < 60) return 'Delayed';
    return 'On-track';
  }

  bool authenticate(String usernameOrEmail, String password) {
    final hashedPassword = sha256.convert(utf8.encode(password)).toString();

    for (var user in _users) {
      final stored = user['password'];
      final matchPlain = stored == password;
      final matchHashed = stored == hashedPassword;

      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail) &&
          (matchPlain || matchHashed)) {
        _currentLoggedInUser = usernameOrEmail;
        return true;
      }
    }
    return false;
  }

  void registerUserWithRole(
    String username,
    String email,
    String rawPassword,
    String role,
  ) {
    if (isUsernameExists(username) || isEmailExists(email)) return;

    final hashedPassword = sha256.convert(utf8.encode(rawPassword)).toString();

    _users.add({
      'id': _uuid.v4(),
      'username': username,
      'email': email,
      'password': hashedPassword,
      'role': role,
      'fullName': '',
    });

    _userProjects[username] = {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };

    _notifEnabled[username] = true;
  }

  void registerUser(String username, String email, String password) {
    registerUserWithRole(username, email, password, 'user');
  }

  void updateUser(
    String oldUsername,
    String email,
    String rawPassword,
    String role, {
    String? newUsername,
  }) {
    for (var user in _users) {
      if (user['username'] == oldUsername && oldUsername != 'admin') {
        if (newUsername != null && newUsername != oldUsername && !isUsernameExists(newUsername)) {
          if (_userProjects.containsKey(oldUsername)) {
            _userProjects[newUsername] = _userProjects.remove(oldUsername)!;
          }
          for (var project in _projects) {
            if (project['members'] is List) {
              project['members'] = (project['members'] as List)
                  .map((m) => m == oldUsername ? newUsername : m)
                  .toList();
            }
          }
          user['username'] = newUsername;
          _notifEnabled[newUsername] = _notifEnabled.remove(oldUsername) ?? true;
          _notificationsByUser[newUsername] =
              _notificationsByUser.remove(oldUsername) ?? [];
          if (_currentLoggedInUser == oldUsername) {
            _currentLoggedInUser = newUsername;
          }
        }

        user['email'] = email;
        final isHashed = rawPassword.length == 64 && !rawPassword.contains(' ');
        user['password'] =
            isHashed ? rawPassword : sha256.convert(utf8.encode(rawPassword)).toString();
        user['role'] = role;
        break;
      }
    }
  }

  Map<String, dynamic>? getUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u['email'] == email);
    } catch (e) {
      return null;
    }
  }

  void addUser(Map<String, dynamic> user) {
    final email = user['email'];
    final username = user['username'];
    if (isEmailExists(email) || isUsernameExists(username)) return;

    final rawPassword = user['password'];
    final hashedPassword = sha256.convert(utf8.encode(rawPassword)).toString();

    _users.add({
      'id': _uuid.v4(),
      'username': username,
      'email': email,
      'password': hashedPassword,
      'role': user['role'],
      'fullName': user['fullName'] ?? '',
    });

    _userProjects[username] = {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };

    _notifEnabled[username] = true;
  }

  bool isUsernameExists(String username) => _users.any((u) => u['username'] == username);
  bool isEmailExists(String email) => _users.any((u) => u['email'] == email);

  String? getUsernameByEmail(String email) =>
      _users.firstWhere((u) => u['email'] == email, orElse: () => {})['username'];
  String? getEmailByUsername(String username) =>
      _users.firstWhere((u) => u['username'] == username, orElse: () => {})['email'];
  String? getUserNameById(String id) =>
      _users.firstWhere((u) => u['username'] == id, orElse: () => {})['username'];
  String? getFullNameByEmail(String email) =>
      _users.firstWhere((u) => u['email'] == email, orElse: () => {})['fullName'];
  String? getFullNameByUsername(String username) =>
      _users.firstWhere((u) => u['username'] == username, orElse: () => {})['fullName'];

  String getUserRole(String id) =>
      _users.firstWhere((u) => u['username'] == id || u['email'] == id,
          orElse: () => {'role': 'user'})['role'];

  bool isAdmin(String id) => getUserRole(id).toLowerCase() == 'admin';
  bool isTeacher(String id) => getUserRole(id).toLowerCase() == 'teacher';
  bool isStudent(String id) => getUserRole(id).toLowerCase() == 'user';
  bool isOfficer(String id) => getUserRole(id).toLowerCase() == 'officer';

  List<Map<String, dynamic>> getAllUsers() => List.from(_users);

  bool isUsernameTaken(String username) => isUsernameExists(username);

  bool updateUsername(String newUsername) {
    if (_currentLoggedInUser == null) return false;
    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
        _notifEnabled[newUsername] = _notifEnabled.remove(user['username']) ?? true;
        _notificationsByUser[newUsername] =
            _notificationsByUser.remove(user['username']) ?? [];

        user['username'] = newUsername;
        _currentLoggedInUser = newUsername;
        return true;
      }
    }
    return false;
  }

  bool updateEmail(String newEmail) {
    if (_currentLoggedInUser == null) return false;
    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
        user['email'] = newEmail;
        _currentLoggedInUser = newEmail;
        return true;
      }
    }
    return false;
  }

  bool updatePassword(String newPassword) {
    if (_currentLoggedInUser == null) return false;
    final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
        user['password'] = hashedPassword;
        return true;
      }
    }
    return false;
  }

  void deleteUser(String username) {
    if (username == 'admin') return;
    _users.removeWhere((u) => u['username'] == username);
    _notificationsByUser.remove(username);
    _notifEnabled.remove(username);
  }

  // -----------------------------
  // LEGACY COURSE APIS (kept for compatibility)
  // -----------------------------
  List<String> getAllCourses() => List.from(_courses);

  void addCourse(String courseName) {
    // Create a rich course with defaults, keep names list in sync
    if (!_courses.contains(courseName)) {
      _courses.add(courseName);
    }
    // if not already present in rich store, add a default record
    final existing = getCourseByName(courseName);
    if (existing == null) {
      createCourse(name: courseName);
    }
  }

  void removeCourse(String courseName) {
    // legacy remove (name only) – map to rich deletion if we can
    final c = getCourseByName(courseName);
    if (c != null) {
      deleteCourseById(c['id'].toString());
    } else {
      // fall back to legacy behavior
      _courses.remove(courseName.trim());
    }
  }

  // (Name-based) delete course + related projects (legacy signature)
  void deleteCourse(String courseName) {
    final c = getCourseByName(courseName);
    if (c != null) {
      deleteCourseById(c['id'].toString());
      return;
    }

    // Fallback: legacy behavior if rich course not found
    _courses.remove(courseName);

    final projectsToDelete = _projects
        .where((p) => p['course'] == courseName)
        .map((p) => p['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    for (final projectName in projectsToDelete) {
      deleteProject(projectName);
    }

    for (final key in _userProjects.keys.toList()) {
      if (_userProjects[key]?['course'] == courseName) {
        final currentProjectName = _userProjects[key]?['project'] ?? '';
        final isDeletedProject = projectsToDelete.contains(currentProjectName);

        _userProjects[key]!['course'] = 'N/A';

        if (isDeletedProject) {
          _userProjects[key]!['project'] = 'N/A';
          _userProjects[key]!['contribution'] = '0%';
          _userProjects[key]!['rank'] = 'Unranked';
          _userProjects[key]!['deadline'] = '';
        }
      }
    }
  }

  void renameCourse(String oldName, String newName) {
    final c = getCourseByName(oldName);
    if (c != null) {
      updateCourse(
        c['id'].toString(),
        name: newName,
      );
      return;
    }

    // Fallback to legacy rename if not in rich store
    if (_courses.contains(oldName) && !_courses.contains(newName)) {
      final index = _courses.indexOf(oldName);
      _courses[index] = newName;

      for (var project in _projects) {
        if (project['course'] == oldName) project['course'] = newName;
      }

      for (var key in _userProjects.keys) {
        if (_userProjects[key]?['course'] == oldName) {
          _userProjects[key]!['course'] = newName;
        }
      }
    }
  }

  List<String> getCourses() => List.from(_courses);

  // -----------------------------
  // PROJECT / COURSE CROSS-OPS & UTILS
  // -----------------------------
  // Completely remove a project and related data
  void deleteProject(String projectName) {
    final index = _projects.indexWhere((p) => p['name'] == projectName);
    if (index == -1) return;

    final project = _projects[index];
    _projectTasks.remove(projectName);
    _projectLeaders.remove(projectName);

    final members = List<String>.from(project['members'] ?? []);
    for (final member in members) {
      if (_userProjects.containsKey(member) &&
          _userProjects[member]?['project'] == projectName) {
        _userProjects[member] = {
          'project': 'N/A',
          'contribution': '0%',
          'rank': 'Unranked',
          'course': 'N/A',
          'deadline': '',
        };
      }
    }
    _projects.removeAt(index);
  }

  void notifyProjectMembers(
    String projectName, {
    required String title,
    required String body,
    String type = 'system',
    String? payload,
  }) {
    final members = getProjectMembers(projectName);
    for (final m in members) {
      _pushNotification(
        m,
        title: title,
        body: body,
        type: type,
        payload: payload ?? projectName,
      );
    }
  }

  // -----------------------------
  // MISC
  // -----------------------------
  String get adminPin => _adminPin;
  String? get currentLoggedInUser => _currentLoggedInUser;
  void logout() => _currentLoggedInUser = null;
}
