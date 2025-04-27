class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();

  factory MockDatabase() => _instance;

  MockDatabase._internal();

  final List<Map<String, String>> _users = [
    {
      'username': 'testuser',
      'email': 'user@example.com',
      'password': 'password123'
    },
    {
      'username': 'admin',
      'email': 'admin@example.com',
      'password': 'adminpass'
    },
  ];

  // ✅ Add these 3 methods below

  bool isUsernameExists(String username) {
    return _users.any((user) => user['username'] == username);
  }

  bool isEmailExists(String email) {
    return _users.any((user) => user['email'] == email);
  }

  void registerUser(String username, String email, String password) {
    _users.add({
      'username': username,
      'email': email,
      'password': password,
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

}
