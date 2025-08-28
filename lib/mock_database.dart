// mock_database.dart
import 'dart:async'; // <-- NEW
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
  // USERS (seed) – unchanged
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
  // NOTIFICATIONS (NEW)
  // -----------------------------
  // username -> notifications list
  final Map<String, List<Map<String, dynamic>>> _notificationsByUser = {};
  // username -> enabled?
  final Map<String, bool> _notifEnabled = {};
  // stream of { 'username': <u>, 'notification': <map> }
  final StreamController<Map<String, dynamic>> _notifStream =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Listen for new notifications in real time
  Stream<Map<String, dynamic>> get notificationStream => _notifStream.stream;

  /// Get notifications for a user (newest first)
  List<Map<String, dynamic>> getNotifications(String username) {
    final list = List<Map<String, dynamic>>.from(
        _notificationsByUser[username] ?? const []);
    list.sort((a, b) =>
        (b['createdAt'] as String).compareTo(a['createdAt'] as String));
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

  bool isNotificationsEnabled(String username) =>
      _notifEnabled[username] ?? true;

  void setNotificationsEnabled(String username, bool enabled) {
    _notifEnabled[username] = enabled;
  }

  void _pushNotification(
    String username, {
    required String title,
    required String body,
    required String type, // 'project_created'|'leader_assigned'|'task_assigned'|'proof_uploaded'|'proof_result'
    String? payload, // e.g., projectName / taskId / etc.
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

    // broadcast for UI badges / local toasts
    _notifStream.add({'username': username, 'notification': n});
  }

  // -----------------------------
  // PROJECTS / TASKS (yours)
  // -----------------------------
  final Map<String, Map<String, String>> _userProjects = {};
  final List<Map<String, dynamic>> _projects = [];
  final List<String> _courses = [];
  String? _currentLoggedInUser;
  final String _adminPin = '1234';

  final Map<String, List<Map<String, dynamic>>> _projectTasks = {};
  final Map<String, String> _projectLeaders = {};

  void assignLeader(String projectName, String username) {
    _projectLeaders[projectName] = username;
    for (var project in _projects) {
      if (project['name'] == projectName) {
        project['leader'] = username;
        break;
      }
    }
    // --- NOTIFY leader
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

    // --- NOTIFY assignee
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

  void submitTaskProof(String projectName, String taskId, String proofText) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;
    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isNotEmpty) {
      task['proof'] = proofText;
      task['status'] = 'awaiting_review';
      task['votes'] = <String, bool>{};
      task['comments'] = <String, String>{};

      // --- NOTIFY reviewers (all members except assignee)
      final allMembers = _projects
              .firstWhere((p) => p['name'] == projectName, orElse: () => {})[
          'members'] as List? ??
          [];
      final assignee = task['assignedTo'];
      final reviewers =
          allMembers.where((m) => m != assignee).cast<String>().toList();

      for (final r in reviewers) {
        _pushNotification(
          r,
          title: 'Task proof submitted',
          body:
              'Proof submitted for "${task['title']}" in "$projectName". Please review.',
          type: 'proof_uploaded',
          payload: taskId,
        );
      }
    }
  }

  void voteOnTask(
      String projectName, String taskId, String voter, bool agree, String comment) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;
    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isNotEmpty && task['status'] == 'awaiting_review') {
      (task['votes'] as Map<String, bool>)[voter] = agree;
      (task['comments'] as Map<String, String>)[voter] = comment;

      final allMembers = _projects
              .firstWhere((p) => p['name'] == projectName, orElse: () => {})[
          'members'] as List? ??
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

  void voteOnSubtask(String projectName, String taskId, int subtaskIndex,
      String voter, bool agree, String comment) {
    final tasks = _projectTasks[projectName];
    if (tasks == null) return;

    final task = tasks.firstWhere((t) => t['id'] == taskId, orElse: () => {});
    if (task.isEmpty) return;

    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtaskIndex < 0 || subtaskIndex >= subtasks.length) return;

    final subtask = subtasks[subtaskIndex];

    // ensure maps exist and have correct typing
    subtask['votes'] = (subtask['votes'] is Map)
        ? Map<String, bool>.from(subtask['votes'] as Map)
        : <String, bool>{};
    subtask['comments'] = (subtask['comments'] is Map)
        ? Map<String, String>.from(subtask['comments'] as Map)
        : <String, String>{};

    // Record vote and comment
    (subtask['votes'] as Map<String, bool>)[voter] = agree;
    (subtask['comments'] as Map<String, String>)[voter] = comment;

    // Get all project members
    final allMembers = _projects
            .firstWhere((p) => p['name'] == projectName, orElse: () => {})[
        'members'] as List? ??
        [];

    // Exclude the assignee from voting logic
    final assignee = task['assignedTo'];
    final eligibleVoters =
        allMembers.where((m) => m != assignee).toList().cast<String>();

    final votes = subtask['votes'] as Map<String, bool>;

    // Wait until all eligible voters have voted
    if (votes.keys.toSet().containsAll(eligibleVoters)) {
      final approvals =
          votes.entries.where((e) => eligibleVoters.contains(e.key) && e.value).length;

      // Approve if more than half of eligible voters voted "yes"
      subtask['status'] =
          approvals > (eligibleVoters.length / 2) ? 'Approved' : 'Rejected';
    }

    if (subtask['comments'] == null || subtask['comments'] is! Map<String, String>) {
      subtask['comments'] = <String, String>{};
    }
  }

  double calculateMainTaskProgress(Map<String, dynamic> task) {
    final subtasks = task['subtasks'] as List<dynamic>;
    if (subtasks.isEmpty) return 0;

    final approvedCount =
        subtasks.where((s) => s['status'] == 'Approved').length;
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

    final existing = (task['subtasks'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];

    final updatedSubtasks = <Map<String, dynamic>>[];
    final addedTitles = <String>[];

    for (final raw in updatedTitles) {
      final t = raw.trim();
      if (t.isEmpty) continue;

      final match = existing.firstWhere(
        (s) => (s['title'] ?? '').toString().trim().toLowerCase() ==
                t.toLowerCase(),
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

    // 🔔 Notify assignee only when NEW subtasks were added
    if (addedTitles.isNotEmpty) {
      final assignedTo = (task['assignedTo'] ?? '').toString();
      final course = (_projects.firstWhere(
        (p) => p['name'] == projectName,
        orElse: () => {},
      )['course'] ?? 'N/A').toString();

      _pushNotification(
        assignedTo,
        title: 'New subtasks assigned',
        body: 'You have been given tasks in $course - $projectName. '
              'Please open the app to check.',
        type: 'task_assigned',
        payload: projectName,
      );
    }
  }

  void submitSubtaskProof(String projectName, String taskId, int subtaskIndex,
      String user, String comment, String imageUrl) {
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
    subtask['submittedBy'] = user; // <-- track submitter

    // --- NOTIFY reviewers (all members except submitter & assignee)
    final allMembers =
        _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {})['members']
                as List? ??
            [];
    final assignee = task['assignedTo'];
    final reviewers = allMembers
        .where((m) => m != user && m != assignee)
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

    // --- NOTIFY submitter about result
    final submitter = (subtask['submittedBy'] ?? '').toString();
    if (submitter.isNotEmpty) {
      final subtaskTitle = (subtask['title'] ?? '').toString();
      _pushNotification(
        submitter,
        title: subtask['status'] == 'Approved'
            ? 'Proof approved'
            : 'Proof rejected',
        body:
            '"$subtaskTitle" in "$projectName" was ${subtask['status'].toString().toLowerCase()}.',
        type: 'proof_result',
        payload: taskId,
      );
    }
  }

  void replaceSubtasks(
      String projectName, String taskId, List<Map<String, dynamic>> newSubtasks) {
    final tasks = _projectTasks[projectName];
    if (tasks != null) {
      final index = tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        tasks[index]['subtasks'] = newSubtasks;
      }
    }
  }

  List<String> getProjectMembers(String projectName) {
    final project =
        _projects.firstWhere((p) => p['name'] == projectName, orElse: () => {});
    return List<String>.from(project['members'] ?? []);
  }

  void addProject(Map<String, String> projectData) {
    final status = calculateStatus(projectData['deadline']!, 0);
    final members =
        projectData['members']!.split(',').map((e) => e.trim()).toList();

    _projects.add({
      'id': _uuid.v4(),
      'name': projectData['name']!,
      'members': members,
      'startDate': projectData['startDate']!,
      'deadline': projectData['deadline']!,
      'status': status,
      'course': projectData['course'] ?? 'N/A',
    });

    // Set project info for the creator (unchanged)
    final username =
        getUsernameByEmail(_currentLoggedInUser ?? '') ?? _currentLoggedInUser;
    if (username != null) {
      _userProjects[username] = {
        'project': projectData['name']!,
        'contribution': '0%',
        'rank': status,
        'course': projectData['course'] ?? 'N/A',
        'deadline': projectData['deadline'] ?? '',
      };
    }

    // --- NOTIFY all members they were added
    final course = projectData['course'] ?? 'N/A';
    for (final m in members) {
      _pushNotification(
        m,
        title: 'New project',
        body: '"${projectData['name']}" ($course) has been created and you were added.',
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

  void setProjectInfoForUser(
      String usernameOrEmail, Map<String, dynamic> projectInfo) {
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

      if ((user['username'] == usernameOrEmail ||
              user['email'] == usernameOrEmail) &&
          (matchPlain || matchHashed)) {
        _currentLoggedInUser = usernameOrEmail;
        return true;
      }
    }
    return false;
  }

  void registerUserWithRole(
      String username, String email, String rawPassword, String role) {
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

    // default notifications ON for new users
    _notifEnabled[username] = true;
  }

  void registerUser(String username, String email, String password) {
    registerUserWithRole(username, email, password, 'user');
  }

  void updateUser(String oldUsername, String email, String rawPassword, String role,
      {String? newUsername}) {
    for (var user in _users) {
      if (user['username'] == oldUsername && oldUsername != 'admin') {
        if (newUsername != null &&
            newUsername != oldUsername &&
            !isUsernameExists(newUsername)) {
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
          // move notif settings + inbox
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

    _notifEnabled[username] = true; // default ON
  }

  bool isUsernameExists(String username) =>
      _users.any((u) => u['username'] == username);
  bool isEmailExists(String email) =>
      _users.any((u) => u['email'] == email);

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

  String getUserRole(String id) => _users
      .firstWhere((u) => u['username'] == id || u['email'] == id,
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
      if (user['username'] == _currentLoggedInUser ||
          user['email'] == _currentLoggedInUser) {
        // move settings + inbox
        _notifEnabled[newUsername] =
            _notifEnabled.remove(user['username']) ?? true;
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
      if (user['username'] == _currentLoggedInUser ||
          user['email'] == _currentLoggedInUser) {
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
      if (user['username'] == _currentLoggedInUser ||
          user['email'] == _currentLoggedInUser) {
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

  List<String> getAllCourses() => List.from(_courses);

  void addCourse(String courseName) {
    if (!_courses.contains(courseName)) {
      _courses.add(courseName);
    }
  }

  void removeCourse(String courseName) {
    _courses.remove(courseName.trim());
  }

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

  // Replace your current deleteCourse with this implementation:
  void deleteCourse(String courseName) {
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
        _userProjects[key]!['course'] = 'N/A';
        if (_userProjects[key]?['project'] == null ||
            _userProjects[key]!['project'] == courseName) {
          _userProjects[key]!['project'] = 'N/A';
          _userProjects[key]!['contribution'] = '0%';
          _userProjects[key]!['rank'] = 'Unranked';
          _userProjects[key]!['deadline'] = '';
        }
      }
    }
  }

  void notifyProjectMembers(String projectName, {
    required String title,
    required String body,
    String type = 'system',
    String? payload,
  }) {
    final members = getProjectMembers(projectName);
    for (final m in members) {
      _pushNotification( // this should be your existing internal method that emits to notificationStream
        m,
        title: title,
        body: body,
        type: type,
        payload: payload ?? projectName,
      );
    }
  }


  void renameCourse(String oldName, String newName) {
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
  String get adminPin => _adminPin;
  String? get currentLoggedInUser => _currentLoggedInUser;
  void logout() => _currentLoggedInUser = null;
}
