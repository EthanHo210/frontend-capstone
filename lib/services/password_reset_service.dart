import 'dart:math';
import '../mock_database.dart';

class PasswordResetRequest {
  final String token;        // long random string
  final String otp;          // 6-digit
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool consumed;

  PasswordResetRequest({
    required this.token,
    required this.otp,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
    this.consumed = false,
  });
}

class PasswordResetService {
  PasswordResetService._();
  static final PasswordResetService instance = PasswordResetService._();

  // in-memory store (mock “server-side”)
  final Map<String, PasswordResetRequest> _byToken = {};

  // 15 minutes expiry window
  Duration get _ttl => const Duration(minutes: 15);

  PasswordResetRequest createRequestForEmail(String email) {
    final db = MockDatabase();
    final user = db.getUserByEmail(email);
    if (user == null) {
      throw StateError('Email not found');
    }

    // generate token + 6-digit OTP
    final token = _randomToken(48);
    final otp = _randomOtp();

    final now = DateTime.now();
    final req = PasswordResetRequest(
      token: token,
      otp: otp,
      email: email,
      createdAt: now,
      expiresAt: now.add(_ttl),
    );
    _byToken[token] = req;
    return req;
  }

  PasswordResetRequest? getByToken(String token) => _byToken[token];

  bool verifyOtp(String token, String otp) {
    final req = _byToken[token];
    if (req == null) return false;
    if (req.consumed) return false;
    if (DateTime.now().isAfter(req.expiresAt)) return false;
    return req.otp == otp.trim();
    // NOTE: you can add rate-limiting or attempt counters here if desired.
  }

  /// Consumes the request and updates the user's password in the mock DB.
  /// Throws if token invalid/expired/consumed.
  void consumeAndUpdatePassword({
    required String token,
    required String newPassword,
  }) {
    final req = _byToken[token];
    if (req == null) {
      throw StateError('Invalid token');
    }
    if (req.consumed) {
      throw StateError('This reset link has already been used.');
    }
    if (DateTime.now().isAfter(req.expiresAt)) {
      throw StateError('This reset link has expired.');
    }

    final db = MockDatabase();
    final user = db.getUserByEmail(req.email);
    if (user == null) {
      throw StateError('User not found');
    }

    // use the DB helper you already have
    db.updatePasswordForUserEmail(req.email, newPassword);

    req.consumed = true; // mark used
  }

  // ---- helpers ----
  String _randomToken(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _randomOtp() {
    final r = Random.secure().nextInt(900000) + 100000; // 100000..999999
    return r.toString();
  }
}
