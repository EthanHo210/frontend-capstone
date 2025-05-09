class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  final List<Map<String, dynamic>> _users = [
    {
      'username': 'testuser1',
      'email': 'user1@example.com',
      'password': 'password123',
      'role': 'user',
    },
    {
      'username': 'testuser2',
      'email': 'user2@example.com',
      'password': 'password123',
      'role': 'user',
    },
    {
      'username': 'testuser3',
      'email': 'user3@example.com',
      'password': 'password123',
      'role': 'user',
    },
    {
      'username': 'teacher1',
      'email': 'teacher@example.com',
      'password': 'teacherpass',
      'role': 'teacher',
    },
    {
      'username': 'admin',
      'email': 'admin@example.com',
      'password': 'adminpass',
      'role': 'admin',
    },
  ];

  final Map<String, Map<String, String>> _userProjects = {
    'testuser1': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    },
    'testuser2': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    },
    'testuser3': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    },
    'teacher1': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    },
    'admin': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    },
  };

  final List<Map<String, String>> _projects = [];

  String? _currentLoggedInUser;
  final String _adminPin = '1234';

  void addProject(Map<String, String> projectData) {
    DateTime deadline = DateTime.parse(projectData['deadline']!);
    int daysLeft = deadline.difference(DateTime.now()).inDays;

    String status;
    if (daysLeft > 14) {
      status = 'On-track';
    } else if (daysLeft > 7) {
      status = 'Delayed';
    } else {
      status = 'Crisis';
    }

    _projects.add({
      'name': projectData['name']!,
      'members': projectData['members']!,
      'startDate': projectData['startDate']!,
      'deadline': projectData['deadline']!,
      'status': status,
      'course': projectData['course'] ?? 'N/A',
    });

    String? username = _currentLoggedInUser;
    for (var u in _users) {
      if (u['email'] == _currentLoggedInUser) {
        username = u['username'];
        break;
      }
    }

    _userProjects[username!] = {
      'project': projectData['name']!,
      'contribution': '0%',
      'rank': status,
      'course': projectData['course'] ?? 'N/A',
      'deadline': projectData['deadline'] ?? '',
    };
  }

  List<Map<String, String>> getAllProjects() => List.from(_projects);

  List<Map<String, String>> getProjectsForCurrentUser() {
    final user = _currentLoggedInUser;
    if (user == null) return [];
    return _projects.where((p) => p['owner'] == user).toList();
  }

  Map<String, String>? getProjectInfoForUser(String usernameOrEmail) {
    String? username = usernameOrEmail;
    for (var user in _users) {
      if (user['email'] == usernameOrEmail) {
        username = user['username'];
        break;
      }
    }
    return _userProjects[username];
  }

  bool isUsernameExists(String username) =>
      _users.any((u) => u['username'] == username);

  bool isEmailExists(String email) =>
      _users.any((u) => u['email'] == email);

  bool authenticate(String usernameOrEmail, String password) {
    for (var user in _users) {
      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail) &&
          user['password'] == password) {
        _currentLoggedInUser = usernameOrEmail;
        return true;
      }
    }
    return false;
  }

  void registerUser(String username, String email, String password) {
    registerUserWithRole(username, email, password, 'user');
  }

  void registerUserWithRole(String username, String email, String password, String role) {
    if (isUsernameExists(username) || isEmailExists(email)) return;

    _users.add({
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    });

    _userProjects[username] = {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };
  }

  void deleteUser(String username) {
    if (username == 'admin') return;
    _users.removeWhere((u) => u['username'] == username);
  }

  Map<String, dynamic>? getUserByUsername(String username) {
    return _users.firstWhere(
      (user) => user['username'] == username,
      orElse: () => {},
    );
  }

  void updateUser(String username, String email, String password, String role) {
    for (var user in _users) {
      if (user['username'] == username && username != 'admin') {
        user['email'] = email;
        user['password'] = password;
        user['role'] = role;
        break;
      }
    }
  }

  String? getEmailByUsername(String username) =>
      _users.firstWhere((u) => u['username'] == username, orElse: () => {})['email'];

  String? getUsernameByEmail(String email) =>
      _users.firstWhere((u) => u['email'] == email, orElse: () => {})['username'];

  String getUserRole(String usernameOrEmail) =>
      _users.firstWhere((u) =>
              u['username'] == usernameOrEmail || u['email'] == usernameOrEmail,
          orElse: () => {'role': 'user'})['role'];

  bool isAdmin(String usernameOrEmail) =>
      getUserRole(usernameOrEmail).toLowerCase() == 'admin';

  bool isTeacher(String usernameOrEmail) =>
      getUserRole(usernameOrEmail).toLowerCase() == 'teacher';

  bool isStudent(String usernameOrEmail) =>
      getUserRole(usernameOrEmail).toLowerCase() == 'user';

  bool updateUsername(String newUsername) {
    if (_currentLoggedInUser == null) return false;
    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
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
    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
        user['password'] = newPassword;
        return true;
      }
    }
    return false;
  }

  void updateProjectInfo(String usernameOrEmail, String project, String contribution, String rank, String course) {
    if (_userProjects.containsKey(usernameOrEmail)) {
      _userProjects[usernameOrEmail] = {
        'project': project,
        'contribution': contribution,
        'rank': rank,
        'course': course,
        'deadline': _userProjects[usernameOrEmail]?['deadline'] ?? '',
      };
    }
  }

  void setProjectInfoForUser(String usernameOrEmail, Map<String, String> projectInfo) {
    String? username = usernameOrEmail;
    for (var user in _users) {
      if (user['email'] == usernameOrEmail) {
        username = user['username'];
        break;
      }
    }

    if (username != null) {
      _userProjects[username] = {
        'project': projectInfo['name'] ?? 'N/A',
        'contribution': projectInfo['completion'] ?? '0%',
        'rank': projectInfo['status'] ?? 'Unranked',
        'course': projectInfo['course'] ?? 'N/A',
        'deadline': projectInfo['deadline'] ?? '',
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

  List<Map<String, dynamic>> getAllUsers() => List.from(_users);
  String get adminPin => _adminPin;
  String? get currentLoggedInUser => _currentLoggedInUser;
  void logout() => _currentLoggedInUser = null;
}
