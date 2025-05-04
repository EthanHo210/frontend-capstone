class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  final List<Map<String, dynamic>> _users = [
    {
      'username': 'testuser',
      'email': 'user@example.com',
      'password': 'password123',
      'role': 'user',
    },
    {
      'username': 'admin',
      'email': 'admin@example.com',
      'password': 'adminpass',
      'role': 'admin',
    },
  ];

  final Map<String, Map<String, String>> _userProjects = {
    'testuser': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
    },
    'admin': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
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
      'rank': 'Unranked',
      'course': projectData['course'] ?? 'N/A',
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

  bool isUsernameExists(String username) => _users.any((u) => u['username'] == username);
  bool isEmailExists(String email) => _users.any((u) => u['email'] == email);

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
    _users.add({
      'username': username,
      'email': email,
      'password': password,
      'role': 'user',
    });

    _userProjects[username] = {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
    };
  }

  void deleteUser(String username) => _users.removeWhere((u) => u['username'] == username);

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
      };
    }
  }

  List<Map<String, dynamic>> getAllUsers() => List.from(_users);
  String get adminPin => _adminPin;
  String? get currentLoggedInUser => _currentLoggedInUser;

  void logout() => _currentLoggedInUser = null;
}
