import 'dart:math';
import 'package:emailjs/emailjs.dart' as emailjs;

class OTPService {
  static final OTPService _instance = OTPService._internal();

  final Map<String, OTPData> _otpStore = {};

  // ─── EmailJS config ────────────────────────────────────────────────────────

  final String _emailjsServiceId = 'service_humtemp12';
  final String _emailjsTemplateId = 'template_uln8yw4';
  final String _emailjsPublicKey = 'qL24MXYoVf2NdZ50B';
  final String _emailjsPrivateKey = 'auQ3OqDQ9UnMU1yBj28Oz';
 

  final Duration _otpValidity = const Duration(minutes: 10);
  final int _maxAttempts = 5;
  final int _resendCooldownSeconds = 30;

  factory OTPService() => _instance;
  OTPService._internal();

  // ── Generate random 6-digit OTP ───────────────────────────────────────────
  String _generateOTP() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString();
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────
  Future<bool> sendOTP(String email) async {
    try {
      final otp = _generateOTP();

      _otpStore[email] = OTPData(
        otp: otp,
        email: email,
        createdAt: DateTime.now(),
        attempts: 0,
      );

      await emailjs.send(
        _emailjsServiceId,
        _emailjsTemplateId,
        {'to_email': email, 'otp': otp, 'user_name': email.split('@')[0]},
        emailjs.Options(
          publicKey: _emailjsPublicKey,
          privateKey: _emailjsPrivateKey,
        ),
      );

      return true;
    } catch (e) {
      _otpStore.remove(email);
      throw Exception('Gagal mengirim OTP: ${e.toString()}');
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<bool> verifyOTP(String email, String otp) async {
    if (!_otpStore.containsKey(email)) {
      throw Exception('OTP tidak ditemukan. Silakan minta OTP baru.');
    }

    final otpData = _otpStore[email]!;

    // Expired?
    if (DateTime.now().difference(otpData.createdAt) >= _otpValidity) {
      _otpStore.remove(email);
      throw Exception('OTP telah expired. Silakan minta OTP baru.');
    }

    // Too many attempts?
    if (otpData.attempts >= _maxAttempts) {
      _otpStore.remove(email);
      throw Exception('Terlalu banyak percobaan. Silakan minta OTP baru.');
    }

    // Wrong OTP?
    if (otpData.otp != otp) {
      otpData.attempts++;
      if (otpData.attempts >= _maxAttempts) {
        _otpStore.remove(email);
        throw Exception('Terlalu banyak percobaan. Silakan minta OTP baru.');
      }
      final remaining = _maxAttempts - otpData.attempts;
      throw Exception('OTP tidak valid. Sisa percobaan: $remaining');
    }

    // Valid — remove
    _otpStore.remove(email);
    return true;
  }

  // ── Resend OTP ────────────────────────────────────────────────────────────
  Future<bool> resendOTP(String email) async {
    if (_otpStore.containsKey(email)) {
      final otpData = _otpStore[email]!;
      final secondsPassed = DateTime.now()
          .difference(otpData.createdAt)
          .inSeconds;
      if (secondsPassed < _resendCooldownSeconds) {
        final waitTime = _resendCooldownSeconds - secondsPassed;
        throw Exception('Tunggu $waitTime detik sebelum meminta OTP baru');
      }
    }
    return sendOTP(email);
  }

  // ── Utilities ─────────────────────────────────────────────────────────────
  void clearOTP(String email) => _otpStore.remove(email);

  /// Returns remaining validity in whole minutes (0 if expired/not found)
  int getRemainingTime(String email) {
    final otpData = _otpStore[email];
    if (otpData == null) return 0;
    final elapsed = DateTime.now().difference(otpData.createdAt);
    final remaining = _otpValidity.inMinutes - elapsed.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Debug only — remove before production
  OTPData? getOTPData(String email) => _otpStore[email];
}

class OTPData {
  final String otp;
  final String email;
  final DateTime createdAt;
  int attempts;

  OTPData({
    required this.otp,
    required this.email,
    required this.createdAt,
    required this.attempts,
  });
}
