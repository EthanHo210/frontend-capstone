class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();

  factory MockDatabase() => _instance;

  MockDatabase._internal();

  final List<Map<String, String>> _users = [
    {'username': 'user1', 'email': 'user@example.com', 'password': 'password123'},
    {'username': 'admin', 'email': 'admin@example.com', 'password': 'adminpass'},
  ];

  void addUser(String username, String email, String password) {
    _users.add({'username': username, 'email': email, 'password': password});
  }

  bool emailExists(String email) {
    return _users.any((user) => user['email'] == email);
  }

  bool usernameExists(String username) {
    return _users.any((user) => user['username'] == username);
  }

  bool authenticate(String identifier, String password) {
    return _users.any((user) =>
      (user['email'] == identifier || user['username'] == identifier) &&
      user['password'] == password);
  }

  String? getUsernameByEmail(String email) {
    return _users.firstWhere(
      (user) => user['email'] == email,
      orElse: () => {},
    )['username'];
  }

  String? getEmailByUsername(String username) {
    return _users.firstWhere(
      (user) => user['username'] == username,
      orElse: () => {},
    )['email'];
  }

  List<Map<String, String>> getAllUsers() => List.unmodifiable(_users);
}
