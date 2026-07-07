// sign_up.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_widgets.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _agreeTerms = false;
  bool _showPass = false;
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final String name = _nameCtrl.text.trim();
    final String email = _emailCtrl.text.trim();
    final String password = _passwordCtrl.text;

    if (name.isEmpty) return 'Nama tidak boleh kosong.';
    if (email.isEmpty) return 'Email tidak boleh kosong.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid.';
    }
    if (password.isEmpty) return 'Password tidak boleh kosong.';
    if (password.length < 6) return 'Password minimal 6 karakter.';
    if (!_agreeTerms) return 'Kamu harus menyetujui Terms of Service.';
    return null;
  }

  Future<void> _createAccount() async {
    final String? error = _validate();
    if (error != null) {
      showAuthToast(context, error, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );

      await cred.user?.updateDisplayName(_nameCtrl.text.trim());
      await cred.user?.reload();

      if (mounted) {
        showAuthToast(context, 'Akun berhasil dibuat! Silakan login.');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/SignIn');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showAuthToast(context, _getErrorMessage(e.code), isError: true);
      }
    } catch (e) {
      if (mounted) {
        showAuthToast(
          context,
          'Terjadi kesalahan yang tidak terduga.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'operation-not-allowed':
        return 'Pendaftaran dengan email dinonaktifkan.';
      default:
        return 'Gagal membuat akun. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Step Dots ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepDot(active: true),
                      const SizedBox(width: 6),
                      _StepDot(active: false),
                      const SizedBox(width: 6),
                      _StepDot(active: false),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Logo ────────────────────────────────────────────────
                  const Center(child: AuthLogoBadge()),
                  const SizedBox(height: 32),

                  // ── Heading ─────────────────────────────────────────────
                  const Text(
                    'Buat Akun',
                    style: TextStyle(
                      color: AppColors.textPri,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor peralatan Anda kapan saja\ndan di mana saja.',
                    style: TextStyle(
                      color: AppColors.textSec,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Nama ────────────────────────────────────────────────
                  const AuthFieldLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: _nameCtrl,
                    hint: 'Nama lengkap Anda',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 18),

                  // ── Email ───────────────────────────────────────────────
                  const AuthFieldLabel('Email'),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: _emailCtrl,
                    hint: 'Masukkan email Anda',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),

                  // ── Password ────────────────────────────────────────────
                  const AuthFieldLabel('Password'),
                  const SizedBox(height: 8),
                  AuthInputField(
                    controller: _passwordCtrl,
                    hint: 'Buat password (min. 6 karakter)',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    showPassword: _showPass,
                    onTogglePassword: () {
                      setState(() => _showPass = !_showPass);
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Terms & Conditions ──────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      setState(() => _agreeTerms = !_agreeTerms);
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            color: _agreeTerms
                                ? AppColors.primary
                                : AppColors.surface,
                            border: Border.all(
                              color: _agreeTerms
                                  ? AppColors.primary
                                  : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: _agreeTerms
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: AppColors.textSec,
                                fontSize: 12.5,
                                height: 1.6,
                              ),
                              children: [
                                TextSpan(text: 'Saya menyetujui '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: ' dan '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Tombol Buat Akun ────────────────────────────────────
                  AuthPrimaryButton(
                    label: 'Buat Akun',
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _createAccount,
                  ),
                  const SizedBox(height: 24),

                  // ── Link ke Sign In ─────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/SignIn');
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Sudah punya akun? ',
                              style: TextStyle(color: AppColors.textSec),
                            ),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step Dot ─────────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active ? AppColors.primary : const Color(0xFFE2E8F0),
      ),
    );
  }
}
