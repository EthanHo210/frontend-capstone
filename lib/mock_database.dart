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

  final String _adminPin = '1234'; // <-- NEW: Admin PIN stored here

  // --- Existing functions ---
  bool isUsernameExists(String username) {
    return _users.any((user) => user['username'] == username);
  }

  bool isEmailExists(String email) {
    return _users.any((user) => user['email'] == email);
  }

  bool isAdmin(String usernameOrEmail) {
    for (var user in _users) {
      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail)) {
        return user['role'] == 'admin'; // <-- FIXED: you had user['isAdmin'], but your data uses 'role'
      }
    }
    return false;
  }

  void registerUser(String username, String email, String password) {
    _users.add({
      'username': username,
      'email': email,
      'password': password,
      'role': 'user', // Always default new user role to 'user'
    });
  }

  bool authenticate(String usernameOrEmail, String password) {
    for (var user in _users) {
      if ((user['username'] == usernameOrEmail || user['email'] == usernameOrEmail) && user['password'] == password) {
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
    return List.from(_users); // Return a copy to avoid direct modifications
  }

  void deleteUser(String username) {
    _users.removeWhere((user) => user['username'] == username);
  }

  String get adminPin => _adminPin; // <-- NEW: expose the admin PIN safely
}
