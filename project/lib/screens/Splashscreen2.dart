import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});
  @override
  SplashScreen2State createState() => SplashScreen2State();
}

class SplashScreen2State extends State<SplashScreen2>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _imageController;
  late AnimationController _waveController;
  late AnimationController _btnController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<Offset> _imageSlideAnim;
  late Animation<double> _imageScaleAnim;
  late Animation<double> _waveAnim;
  late Animation<double> _btnAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _imageSlideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));
    _imageScaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));
    _waveAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_waveController);
    _btnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _imageController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _btnController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _imageController.dispose();
    _waveController.dispose();
    _btnController.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B4B), Color(0xFF1E3A8A), Color(0xFF1E40AF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Gelombang animasi background ──────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _waveAnim,
                builder: (context, _) => CustomPaint(
                  size: Size(size.width, 180),
                  painter: WavePainter(_waveAnim.value),
                ),
              ),
            ),

            // ── Dot dekorasi kiri atas ────────────────────────────────────
            Positioned(
              top: 60,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF60A5FA).withOpacity(0.08),
                ),
              ),
            ),

            // ── Konten utama ──────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Ilustrasi atas
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: SlideTransition(
                        position: _imageSlideAnim,
                        child: ScaleTransition(
                          scale: _imageScaleAnim,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Glow circle
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.07),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.3),
                                      blurRadius: 50,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Image.network(
                                      "https://storage.googleapis.com/tagjs-prod.appspot.com/v1/QT9Oe2IIUs/8lahdr6a_expires_30_days.png",
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.devices_rounded,
                                        color: Colors.white,
                                        size: 80,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Badge sensor kiri atas
                              Positioned(
                                top: 10,
                                left: 10,
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: _buildBadge(
                                    icon: Icons.thermostat_rounded,
                                    label: "Temp",
                                    value: "29.8°C",
                                    color: const Color(0xFFFF6B6B),
                                  ),
                                ),
                              ),

                              // Badge humidity kanan bawah
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: FadeTransition(
                                  opacity: _fadeAnim,
                                  child: _buildBadge(
                                    icon: Icons.water_drop_outlined,
                                    label: "Humid",
                                    value: "68.2%",
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Teks + tombol bawah
                  Expanded(
                    flex: 4,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Judul
                              const Text(
                                "The Simple Way to",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 4),

                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF60A5FA),
                                        Color(0xFF93C5FD),
                                      ],
                                    ).createShader(bounds),
                                child: const Text(
                                  "Monitor Everything!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Deskripsi
                              Text(
                                "Stay updated with real-time environmental\nmeasurements and device status.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 36),

                              // Dot indikator + tombol Next
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Dot indikator
                                  Row(
                                    children: [
                                      _buildDot(active: false),
                                      const SizedBox(width: 6),
                                      _buildDot(active: true),
                                    ],
                                  ),

                                  // Tombol Get Started
                                  ScaleTransition(
                                    scale: _btnAnim,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/SignIn',
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF3B82F6),
                                              Color(0xFF60A5FA),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF3B82F6,
                                              ).withOpacity(0.5),
                                              blurRadius: 20,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Get Started",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF60A5FA) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────

class WavePainter extends CustomPainter {
  final double t;
  WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1
    final p1 = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height * 0.5 +
          20 * math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi);
      path1.lineTo(x, y);
    }
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, p1);

    // Wave 2
    final p2 = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    for (double x = 0; x <= size.width; x++) {
      final y =
          size.height * 0.65 +
          15 *
              math.sin(
                (x / size.width * 2 * math.pi) + (t + 0.4) * 2 * math.pi,
              );
      path2.lineTo(x, y);
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.t != t;
}
