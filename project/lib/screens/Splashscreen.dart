import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _orbitAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _orbitAnim = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_orbitController);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _particleAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _slideController.forward();
    });

    // Auto navigate setelah 3.5 detik
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/Splashscreen2');
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B4B),
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
              Color(0xFF2563EB),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Partikel background
            AnimatedBuilder(
              animation: _particleAnim,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: Splash1ParticlePainter(_particleAnim.value),
              ),
            ),

            // Lingkaran orbit
            AnimatedBuilder(
              animation: _orbitAnim,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: Splash1OrbitPainter(_orbitAnim.value),
              ),
            ),

            // Konten utama
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo circle
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnim.value,
                        child: child,
                      ),
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF60A5FA).withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Image.network(
                                "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/ucim2tb0_expires_30_days.png",
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.thermostat_rounded,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Column(
                          children: [
                            // Nama app shimmer
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Colors.white,
                                  Color(0xFF93C5FD),
                                  Colors.white,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                "HumTemp",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "Smart Environmental Monitor",
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                "Monitor temperature and humidity\nin real time, anytime and anywhere.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  height: 1.7,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading dots bawah
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _particleAnim,
                      builder: (context, _) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final delay = i / 3;
                            final t = (_particleAnim.value + delay) % 1.0;
                            final scale =
                                0.4 + 0.6 * math.sin(t * math.pi).abs();
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(
                                  0.2 + 0.6 * scale,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "LOADING",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

class Splash1ParticlePainter extends CustomPainter {
  final double t;
  Splash1ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = [
      [0.1, 0.15, 1.8, 0.04, 0.0],
      [0.3, 0.7, 1.2, 0.03, 1.0],
      [0.5, 0.3, 2.0, 0.05, 2.0],
      [0.7, 0.8, 1.5, 0.035, 3.0],
      [0.9, 0.2, 1.0, 0.025, 4.0],
      [0.2, 0.9, 2.2, 0.045, 0.5],
      [0.6, 0.5, 1.3, 0.03, 1.5],
      [0.8, 0.4, 1.8, 0.04, 2.5],
      [0.15, 0.6, 1.0, 0.02, 3.5],
      [0.45, 0.85, 2.0, 0.05, 0.8],
      [0.75, 0.15, 1.5, 0.035, 4.2],
      [0.35, 0.45, 1.2, 0.025, 1.8],
      [0.55, 0.65, 2.5, 0.055, 2.8],
      [0.85, 0.75, 1.0, 0.02, 0.2],
      [0.25, 0.25, 1.8, 0.04, 3.8],
    ];
    for (final p in rng) {
      final y = (p[1] + t * p[3]) % 1.0;
      final x = p[0] + 0.015 * math.sin(t * 2 * math.pi + p[4]);
      final op = 0.08 + 0.18 * math.sin(t * math.pi + p[4]).abs();
      paint.color = Colors.white.withOpacity(op.clamp(0.04, 0.26));
      canvas.drawCircle(Offset(x * size.width, y * size.height), p[2], paint);
    }
  }

  @override
  bool shouldRepaint(Splash1ParticlePainter old) => old.t != t;
}

class Splash1OrbitPainter extends CustomPainter {
  final double angle;
  Splash1OrbitPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    ringPaint.color = Colors.white.withOpacity(0.04);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.65, ringPaint);
    ringPaint.color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(Offset(cx, cy), size.width * 0.44, ringPaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;

    final r1 = size.width * 0.44;
    dotPaint.color = const Color(0xFF60A5FA).withOpacity(0.5);
    canvas.drawCircle(
      Offset(cx + r1 * math.cos(angle), cy + r1 * math.sin(angle)),
      5,
      dotPaint,
    );

    final r2 = size.width * 0.65;
    dotPaint.color = Colors.white.withOpacity(0.25);
    canvas.drawCircle(
      Offset(
        cx + r2 * math.cos(-angle * 0.7),
        cy + r2 * math.sin(-angle * 0.7),
      ),
      3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(Splash1OrbitPainter old) => old.angle != angle;
}
