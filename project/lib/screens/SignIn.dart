// sign_in.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_widgets.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> with SingleTickerProviderStateMixin {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _showPass = false;
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.currentUser != null && mounted) {
        Navigator.pushReplacementNamed(context, '/Dashboard');
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      showAuthToast(context, 'Silakan isi email dan password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        showAuthToast(context, 'Login berhasil!');
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/Dashboard');
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
          'Terjadi kesalahan yang tidak terduga',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Login gagal. Silakan coba lagi.';
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
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Logo ────────────────────────────────────────────────
                  const Center(child: AuthLogoBadge()),
                  const SizedBox(height: 36),

                  // ── Heading ─────────────────────────────────────────────
                  const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      color: AppColors.textPri,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk ke akun Anda untuk memantau\nperalatan secara real-time.',
                    style: TextStyle(
                      color: AppColors.textSec,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),

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
                    hint: 'Masukkan password Anda',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    showPassword: _showPass,
                    onTogglePassword: () {
                      setState(() => _showPass = !_showPass);
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Lupa Password ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/ForgetPassword');
                      },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Tombol Login ────────────────────────────────────────
                  AuthPrimaryButton(
                    label: 'Log In',
                    isLoading: _isLoading,
                    onTap: _isLoading ? null : _signIn,
                  ),
                  const SizedBox(height: 28),

                  // ── Link Daftar ─────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/SignUp');
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Belum punya akun? ',
                              style: TextStyle(color: AppColors.textSec),
                            ),
                            TextSpan(
                              text: 'Daftar Sekarang',
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
