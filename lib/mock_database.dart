class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();

  factory MockDatabase() => _instance;

  MockDatabase._internal();

  final List<Map<String, String>> _users = [
    {'email': 'user@example.com', 'password': 'password123'},
    {'email': 'admin@example.com', 'password': 'adminpass'},
  ];

  bool authenticate(String email, String password) {
    return _users.any((user) =>
        user['email'] == email && user['password'] == password);
  }

  bool emailExists(String email) {
    return _users.any((user) => user['email'] == email);
  }

  void addUser(String email, String password) {
    _users.add({'email': email, 'password': password});
  }
}
