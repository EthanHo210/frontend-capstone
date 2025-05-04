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
    },
    'admin': {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
    },
  };

  Map<String, String>? getProjectInfoForUser(String usernameOrEmail) {
    return _userProjects[usernameOrEmail];
  }

  final String _adminPin = '1234'; // Admin PIN stored here
  String? _currentLoggedInUser; // <-- Store current logged-in user


  bool isUsernameExists(String username) {
    return _users.any((user) => user['username'] == username);
  }

  bool isEmailExists(String email) {
    return _users.any((user) => user['email'] == email);
  }

  bool isAdmin(String usernameOrEmail) {
    for (var user in _users) {
      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail)) {
        return user['role'] == 'admin';
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
  }

  bool authenticate(String usernameOrEmail, String password) {
    for (var user in _users) {
      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail) && user['password'] == password) {
        _currentLoggedInUser = usernameOrEmail; // <-- Save who logged in
        return true;
      }
    }
    return false;
  }

  String? getEmailByUsername(String username) {
    for (var user in _users) {
      if (user['username'] == username) {
        return user['email'];
      }
    }
    return null;
  }

  String? getUsernameByEmail(String email) {
    for (var user in _users) {
      if (user['email'] == email) {
        return user['username'];
      }
    }
    return null;
  }

  String getUserRole(String usernameOrEmail) {
    for (var user in _users) {
      if (user['username'] == usernameOrEmail || user['email'] == usernameOrEmail) {
        return user['role'] ?? 'user';
      }
    }
    return 'user';
  }

  List<Map<String, dynamic>> getAllUsers() {
    return List.from(_users); // Return a copy
  }

  void deleteUser(String username) {
    _users.removeWhere((user) => user['username'] == username);
  }

  // --- New functions for session ---
  String get adminPin => _adminPin;
  String? get currentLoggedInUser => _currentLoggedInUser;

  void logout() {
    _currentLoggedInUser = null;
  }

  // --- New functions for updating account info ---
  bool updateUsername(String newUsername) {
    if (_currentLoggedInUser == null) return false;

    for (var user in _users) {
      if (user['username'] == _currentLoggedInUser || user['email'] == _currentLoggedInUser) {
        user['username'] = newUsername;
        _currentLoggedInUser = newUsername; // Update current session too
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
        _currentLoggedInUser = newEmail; // Update current session too
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

  void updateProjectInfo(String usernameOrEmail, String project, String contribution, String rank) {
    if (_userProjects.containsKey(usernameOrEmail)) {
      _userProjects[usernameOrEmail] = {
        'project': project,
        'contribution': contribution,
        'rank': rank,
      };
    }
  }
}
