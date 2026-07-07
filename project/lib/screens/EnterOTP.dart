import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/OTPService.dart';

class EnterOTP extends StatefulWidget {
  const EnterOTP({super.key});
  @override
  EnterOTPState createState() => EnterOTPState();
}

class EnterOTPState extends State<EnterOTP> {
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  bool isLoading = false;
  String email = '';
  int resendCountdown = 0;
  Timer? _countdownTimer;
  final OTPService _otpService = OTPService();

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      if (mounted) {
        setState(() {});
        _startResendCountdown();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown([int seconds = 60]) {
    _countdownTimer?.cancel();
    setState(() => resendCountdown = seconds);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        resendCountdown--;
        if (resendCountdown <= 0) timer.cancel();
      });
    });
  }

  String _getOTPCode() => _otpControllers.map((c) => c.text).join();

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    final otp = _getOTPCode();
    if (otp.length < 6) {
      _showErrorSnackBar('Masukkan 6 digit kode OTP');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Step 1: Verifikasi OTP via EmailJS / OTPService
      await _otpService.verifyOTP(email, otp);

      // Step 2: OTP valid → Firebase kirim email reset link ke user
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        _showSuccessSnackBar('OTP verified! Cek email untuk reset password.');
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (mounted) {
        // Step 3: Tampilkan halaman instruksi (bukan form input password)
        Navigator.pushNamed(context, '/ResetPassword', arguments: email);
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Email tidak terdaftar di Firebase.';
          break;
        case 'invalid-email':
          msg = 'Format email tidak valid.';
          break;
        case 'too-many-requests':
          msg = 'Terlalu banyak request. Coba lagi nanti.';
          break;
        default:
          msg = 'Gagal mengirim email reset: ${e.message}';
      }
      _showErrorSnackBar(msg);
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOTP() async {
    if (resendCountdown > 0) {
      _showErrorSnackBar(
        'Tunggu $resendCountdown detik sebelum mengirim ulang OTP',
      );
      return;
    }

    try {
      await _otpService.resendOTP(email);
      if (mounted) {
        _showSuccessSnackBar('OTP berhasil dikirim ulang ke $email');
        for (final c in _otpControllers) c.clear();
        _focusNodes[0].requestFocus();
        _startResendCountdown(60);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE4E9F2)),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildStepDots(step: 1),
                    const SizedBox(height: 48),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF3461FD),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Masukkan OTP',
                      style: TextStyle(
                        color: Color(0xFF2A4ECA),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Masukkan kode OTP 6 digit yang telah\nkami kirim ke $email',
                      style: const TextStyle(
                        color: Color(0xFF61677D),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 48,
                          height: 56,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              color: Color(0xFF1A1F36),
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF5F9FD),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E9F2),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE4E9F2),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3461FD),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else {
                                  _focusNodes[index].unfocus();
                                }
                              } else if (index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3461FD),
                          disabledBackgroundColor: const Color(0xFFB0B8C9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verifikasi OTP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tidak menerima OTP? ',
                          style: TextStyle(
                            color: Color(0xFF61677D),
                            fontSize: 14,
                          ),
                        ),
                        resendCountdown > 0
                            ? Text(
                                'Kirim ulang ($resendCountdown)',
                                style: const TextStyle(
                                  color: Color(0xFF9BA5BB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : GestureDetector(
                                onTap: _resendOTP,
                                child: const Text(
                                  'Kirim ulang',
                                  style: TextStyle(
                                    color: Color(0xFF3461FD),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Image.network(
            'https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/jhvtqomy_expires_30_days.png',
            width: 54,
            height: 18,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'MonitorApp',
              style: TextStyle(
                color: Color(0xFF3461FD),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDots({required int step}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == step;
        return Container(
          margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isActive ? const Color(0xFF3461FD) : const Color(0xFFD6DFFF),
          ),
        );
      }),
    );
  }
}
