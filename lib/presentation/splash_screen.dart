// presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnugamiSplashScreen extends StatefulWidget {
  const AnugamiSplashScreen({Key? key}) : super(key: key);

  @override
  State<AnugamiSplashScreen> createState() => _AnugamiSplashScreenState();
}

class _AnugamiSplashScreenState extends State<AnugamiSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _ringController;
  late AnimationController _pulseController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _ringController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    ));

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _textController.forward();
    // ✅ Splash sirf animate karta hai — navigate nahi karta
    // Navigation MyApp._initializeApp() complete hone pe hoti hai
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: MadhubaniBackgroundPainter(
                  animationValue: _backgroundController.value,
                ),
                size: Size(size.width, size.height),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _ringController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color(0xFFF96A4C).withOpacity(
                                        0.3 + (_pulseController.value * 0.3),
                                      ),
                                      blurRadius:
                                          40 + (_pulseController.value * 20),
                                      spreadRadius:
                                          20 + (_pulseController.value * 10),
                                    ),
                                  ],
                                ),
                              ),
                              CustomPaint(
                                size: const Size(240, 240),
                                painter: RotatingRingsPainter(
                                  animationValue: _ringController.value,
                                  ringCount: 3,
                                ),
                              ),
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFFEAF4E).withOpacity(0.2),
                                      const Color(0xFFF96A4C).withOpacity(0.3),
                                      const Color(0xFFE54481).withOpacity(0.2),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFEAF4E)
                                          .withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFEAF4E),
                                      Color(0xFFF96A4C),
                                      Color(0xFFE54481),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF96A4C)
                                          .withOpacity(0.5),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 40,
                                      spreadRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/anugami_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Center(
                                          child: ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                              colors: [
                                                Color(0xFFFEAF4E),
                                                Color(0xFFF96A4C),
                                                Color(0xFFE54481),
                                              ],
                                            ).createShader(bounds),
                                            child: const Icon(
                                              Icons.shopping_bag_rounded,
                                              size: 80,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(160, 160),
                                painter: SparklesPainter(
                                  animationValue: _ringController.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFEAF4E),
                                Color(0xFFF96A4C),
                                Color(0xFFE54481),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'ANUGAMI',
                              style: TextStyle(
                                fontFamily: 'GoodTimes',
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF96A4C),
                                  Color(0xFFE54481),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Empowering the essence of Made In India',
                              style: TextStyle(
                                fontFamily: 'GoodTimes',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(flex: 2),
                // ✅ Loading indicator — dikhata hai ki data load ho raha hai
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFEAF4E),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background Painter ─────────────────────────────────────────────────────────
class MadhubaniBackgroundPainter extends CustomPainter {
  final double animationValue;
  MadhubaniBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0f2027),
          Color(0xFF203a43),
          Color(0xFF2c5364),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
    _drawMadhubaniPatterns(canvas, size);
    _drawFloralMotifs(canvas, size);
    _drawGeometricPatterns(canvas, size);
    _drawBorderDesign(canvas, size);
  }

  void _drawMadhubaniPatterns(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final colors = [
      const Color(0xFFFF6B35).withOpacity(0.3),
      const Color(0xFFF7931E).withOpacity(0.3),
      const Color(0xFFFFD700).withOpacity(0.3),
      const Color(0xFFE74C3C).withOpacity(0.3),
    ];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      _drawConcentricCircles(
          canvas,
          Offset(-50 + math.sin(animationValue * 2 * math.pi) * 20, -50),
          150 + i * 30,
          paint);
      _drawConcentricCircles(
          canvas,
          Offset(size.width + 50 + math.cos(animationValue * 2 * math.pi) * 20,
              size.height + 50),
          150 + i * 30,
          paint);
      _drawConcentricCircles(
          canvas,
          Offset(size.width + 30,
              100 + math.sin(animationValue * 2 * math.pi + 1) * 15),
          100 + i * 25,
          paint);
      _drawConcentricCircles(
          canvas,
          Offset(
              -30,
              size.height -
                  100 +
                  math.cos(animationValue * 2 * math.pi + 2) * 15),
          100 + i * 25,
          paint);
    }
  }

  void _drawConcentricCircles(
      Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
  }

  void _drawFloralMotifs(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final colors = [
      const Color(0xFFFF6B35).withOpacity(0.4),
      const Color(0xFFF7931E).withOpacity(0.4),
      const Color(0xFFFFD700).withOpacity(0.4),
    ];
    final positions = [
      Offset(size.width * 0.15, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.35),
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.75, size.height * 0.15),
    ];
    for (int i = 0; i < positions.length; i++) {
      paint.color = colors[i % colors.length];
      _drawFlower(canvas, positions[i], 30, paint);
    }
  }

  void _drawFlower(Canvas canvas, Offset center, double size, Paint paint) {
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2 / 6) + (animationValue * math.pi / 4);
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * size * 0.6,
            center.dy + math.sin(angle) * size * 0.6),
        size * 0.4,
        paint,
      );
    }
    canvas.drawCircle(center, size * 0.3, paint);
  }

  void _drawGeometricPatterns(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final colors = [
      const Color(0xFFE74C3C).withOpacity(0.3),
      const Color(0xFFFFD700).withOpacity(0.3),
    ];
    for (int i = 0; i < 3; i++) {
      paint.color = colors[i % colors.length];
      _drawDiamond(
          canvas,
          Offset(
              size.width * (0.3 + i * 0.2),
              size.height * 0.5 +
                  math.sin(animationValue * 2 * math.pi + i) * 50),
          40,
          paint);
    }
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, paint);
    final innerSize = size * 0.6;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - innerSize)
        ..lineTo(center.dx + innerSize, center.dy)
        ..lineTo(center.dx, center.dy + innerSize)
        ..lineTo(center.dx - innerSize, center.dy)
        ..close(),
      paint,
    );
  }

  void _drawBorderDesign(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFD700).withOpacity(0.2);
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawCircle(Offset(x, 20), 5, paint);
      canvas.drawCircle(Offset(x, size.height - 20), 5, paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawCircle(Offset(20, y), 5, paint);
      canvas.drawCircle(Offset(size.width - 20, y), 5, paint);
    }
  }

  @override
  bool shouldRepaint(MadhubaniBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ── Rotating Rings Painter ─────────────────────────────────────────────────────
class RotatingRingsPainter extends CustomPainter {
  final double animationValue;
  final int ringCount;
  RotatingRingsPainter({required this.animationValue, required this.ringCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final colors = [
      const Color(0xFFFEAF4E),
      const Color(0xFFF96A4C),
      const Color(0xFFE54481),
    ];
    for (int i = 0; i < ringCount; i++) {
      final radius = (size.width / 2) - (i * 15);
      final rotation = (animationValue * 2 * math.pi) + (i * math.pi / 3);
      for (int j = 0; j < 3; j++) {
        final startAngle = rotation + (j * 2 * math.pi / 3);
        const sweepAngle = math.pi / 2;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              colors[j % 3].withOpacity(0.8),
              colors[(j + 1) % 3].withOpacity(0.3)
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawPath(
          Path()
            ..addArc(Rect.fromCircle(center: center, radius: radius),
                startAngle, sweepAngle),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RotatingRingsPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

// ── Sparkles Painter ───────────────────────────────────────────────────────────
class SparklesPainter extends CustomPainter {
  final double animationValue;
  SparklesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final colors = [
      const Color(0xFFFEAF4E),
      const Color(0xFFF96A4C),
      const Color(0xFFE54481),
    ];
    for (int i = 0; i < 8; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 4);
      final x = center.dx + math.cos(angle) * radius * 0.85;
      final y = center.dy + math.sin(angle) * radius * 0.85;
      final sizeMultiplier =
          0.5 + (math.sin(angle + animationValue * 4 * math.pi) * 0.5);
      final sparkleSize = 3.0 * sizeMultiplier;
      canvas.drawPath(
        Path()
          ..moveTo(x, y - sparkleSize)
          ..lineTo(x + sparkleSize * 0.5, y)
          ..lineTo(x, y + sparkleSize)
          ..lineTo(x - sparkleSize * 0.5, y)
          ..close(),
        Paint()
          ..color = colors[i % 3].withOpacity(0.6 + sizeMultiplier * 0.4)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize,
        Paint()
          ..color = colors[i % 3].withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(SparklesPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
