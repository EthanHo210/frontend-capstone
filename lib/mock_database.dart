import 'dart:convert';
import 'package:crypto/crypto.dart';

class MockDatabase {
  static final MockDatabase _instance = MockDatabase._internal();
  factory MockDatabase() => _instance;
  MockDatabase._internal();

  final List<Map<String, dynamic>> _users = [
    {
      'username': 'testuser1',
      'email': 'user1@example.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
    },
    {
      'username': 'testuser2',
      'email': 'user2@example.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
    },
    {
      'username': 'testuser3',
      'email': 'user3@example.com',
      'password': sha256.convert(utf8.encode('password123')).toString(),
      'role': 'user',
    },
    {
      'username': 'teacher1',
      'email': 'teacher@example.com',
      'password': sha256.convert(utf8.encode('teacherpass')).toString(),
      'role': 'teacher',
    },
    {
      'username': 'admin',
      'email': 'admin@example.com',
      'password': sha256.convert(utf8.encode('adminpass')).toString(),
      'role': 'admin',
    },
    {
      'username': 'officer1',
      'email': 'officer@example.com',
      'password': sha256.convert(utf8.encode('officerpass')).toString(),
      'role': 'officer',
    },
  ];

  final Map<String, Map<String, String>> _userProjects = {};
  final List<Map<String, dynamic>> _projects = [];
  final List<String> _courses = [];
  String? _currentLoggedInUser;
  final String _adminPin = '1234';

  
  void addProject(Map<String, String> projectData) {
    final status = calculateStatus(projectData['deadline']!, 0);
    final members = projectData['members']!.split(',').map((e) => e.trim()).toList();

    _projects.add({
      'name': projectData['name']!,
      'members': members,
      'startDate': projectData['startDate']!,
      'deadline': projectData['deadline']!,
      'status': status,
      'course': projectData['course'] ?? 'N/A',
    });

    final username = getUsernameByEmail(_currentLoggedInUser ?? '') ?? _currentLoggedInUser;
    if (username != null) {
      _userProjects[username] = {
        'project': projectData['name']!,
        'contribution': '0%',
        'rank': status,
        'course': projectData['course'] ?? 'N/A',
        'deadline': projectData['deadline'] ?? '',
      };
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

  void registerUserWithRole(String username, String email, String rawPassword, String role) {
    if (isUsernameExists(username) || isEmailExists(email)) return;

    final hashedPassword = sha256.convert(utf8.encode(rawPassword)).toString();

    _users.add({
      'username': username,
      'email': email,
      'password': hashedPassword,
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

  void registerUser(String username, String email, String password) {
    registerUserWithRole(username, email, password, 'user');
  }

  void updateUser(String oldUsername, String email, String rawPassword, String role, {String? newUsername}) {
    for (var user in _users) {
      if (user['username'] == oldUsername && oldUsername != 'admin') {
        if (newUsername != null && newUsername != oldUsername && !isUsernameExists(newUsername)) {
          if (_userProjects.containsKey(oldUsername)) {
            _userProjects[newUsername] = _userProjects.remove(oldUsername)!;
          }
          for (var project in _projects) {
            if (project['members'] is List) {
              project['members'] = (project['members'] as List).map((m) => m == oldUsername ? newUsername : m).toList();
            }
          }
          user['username'] = newUsername;
          if (_currentLoggedInUser == oldUsername) {
            _currentLoggedInUser = newUsername;
          }
        }

        user['email'] = email;
        final isHashed = rawPassword.length == 64 && !rawPassword.contains(' ');
        user['password'] = isHashed ? rawPassword : sha256.convert(utf8.encode(rawPassword)).toString();
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
      'username': username,
      'email': email,
      'password': hashedPassword,
      'role': user['role'],
    });

    _userProjects[username] = {
      'project': 'N/A',
      'contribution': '0%',
      'rank': 'Unranked',
      'course': 'N/A',
      'deadline': '',
    };
  }


  bool isUsernameExists(String username) => _users.any((u) => u['username'] == username);
  bool isEmailExists(String email) => _users.any((u) => u['email'] == email);

  String? getUsernameByEmail(String email) => _users.firstWhere((u) => u['email'] == email, orElse: () => {})['username'];
  String? getEmailByUsername(String username) => _users.firstWhere((u) => u['username'] == username, orElse: () => {})['email'];
  String? getUserNameById(String id) => _users.firstWhere((u) => u['username'] == id, orElse: () => {})['username'];

  String getUserRole(String id) =>
      _users.firstWhere((u) => u['username'] == id || u['email'] == id, orElse: () => {'role': 'user'})['role'];

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

  void deleteCourse(String courseName) {
    _courses.remove(courseName);
    for (var project in _projects) {
      if (project['course'] == courseName) project['course'] = 'N/A';
    }
    for (var key in _userProjects.keys) {
      if (_userProjects[key]?['course'] == courseName) {
        _userProjects[key]!['course'] = 'N/A';
      }
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
