import 'package:flutter/material.dart';
import '../services/OTPService.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});
  @override
  ForgetPasswordState createState() => ForgetPasswordState();
}

class ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  final OTPService _otpService = OTPService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

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

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Masukkan alamat email Anda');
      return;
    }
    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Format email tidak valid');
      return;
    }

    setState(() => isLoading = true);

    try {
      await _otpService.sendOTP(email);
      _showSuccessSnackBar('Kode OTP berhasil dikirim ke $email');
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushNamed(context, '/EnterOTP', arguments: email);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Back button
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

                    // Step dots
                    _buildStepDots(step: 0),
                    const SizedBox(height: 48),

                    // Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: Color(0xFF3461FD),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Lupa Password',
                      style: TextStyle(
                        color: Color(0xFF2A4ECA),
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Masukkan email terdaftar Anda untuk menerima kode OTP untuk mereset password.',
                      style: TextStyle(
                        color: Color(0xFF61677D),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1A1F36),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email terdaftar Anda',
                        hintStyle: const TextStyle(color: Color(0xFF9BA5BB)),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: Color(0xFF9BA5BB),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F9FD),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E9F2),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE4E9F2),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF3461FD),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _sendOTP(),
                    ),
                    const SizedBox(height: 32),

                    // Send OTP button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _sendOTP,
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
                                'Kirim Kode OTP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
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
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────

Widget _buildTopBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: Row(
      children: [
        Image.network(
          'https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/dy31vuos_expires_30_days.png',
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
