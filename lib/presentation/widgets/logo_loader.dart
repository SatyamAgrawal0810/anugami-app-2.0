// presentation/widgets/logo_loader.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// -------------------------------
/// LOGO LOADER WIDGET
/// -------------------------------
class LogoLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const LogoLoader({
    Key? key,
    this.size = 50,
    this.color,
  }) : super(key: key);

  @override
  State<LogoLoader> createState() => _LogoLoaderState();
}

class _LogoLoaderState extends State<LogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _logo;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _loadLogo();
  }

  Future<void> _loadLogo() async {
    final data = await rootBundle.load('assets/images/app_icon.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    if (mounted) {
      setState(() {
        _logo = frame.image;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_logo == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: LogoLoaderPainter(
              animationValue: _controller.value,
              color: widget.color ?? Theme.of(context).primaryColor,
              logo: _logo!,
            ),
          );
        },
      ),
    );
  }
}

/// -------------------------------
/// CUSTOM PAINTER
/// -------------------------------
class LogoLoaderPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final ui.Image logo;

  LogoLoaderPainter({
    required this.animationValue,
    required this.color,
    required this.logo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    /// Rotating dots
    for (int i = 0; i < 3; i++) {
      final angle = animationValue * 2 * math.pi + i * 2 * math.pi / 3;

      final offset = Offset(
        center.dx + math.cos(angle) * radius * 0.6,
        center.dy + math.sin(angle) * radius * 0.6,
      );

      final paint = Paint()
        ..color = color.withOpacity(0.7 - i * 0.2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offset, radius * 0.18, paint);
    }

    /// Center logo
    final logoSize = size.width * 0.5;

    final dstRect = Rect.fromCenter(
      center: center,
      width: logoSize,
      height: logoSize,
    );

    final srcRect = Rect.fromLTWH(
      0,
      0,
      logo.width.toDouble(),
      logo.height.toDouble(),
    );

    canvas.drawImageRect(
      logo,
      srcRect,
      dstRect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant LogoLoaderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.logo != logo ||
        oldDelegate.color != color;
  }
}
