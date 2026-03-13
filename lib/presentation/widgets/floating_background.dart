// lib/presentation/widgets/floating_background.dart
// Reusable floating background animation component

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Model for floating icon configuration
class FloatingIconConfig {
  final IconData icon;
  final Color color;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

  const FloatingIconConfig({
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

/// Animated floating background with icons
///
/// This widget creates an animated background with floating icons
/// that move slowly across the screen. It's used to add visual
/// interest to various pages without being distracting.
class FloatingBackground extends StatefulWidget {
  final Color primaryColor;
  final List<IconData>? customIcons;
  final int iconCount;
  final Duration animationDuration;
  final double opacity;

  const FloatingBackground({
    Key? key,
    required this.primaryColor,
    this.customIcons,
    this.iconCount = AppConstants.floatingIconCount,
    this.animationDuration = AppConstants.floatingBackgroundDuration,
    this.opacity = AppConstants.floatingIconOpacity,
  }) : super(key: key);

  @override
  State<FloatingBackground> createState() => _FloatingBackgroundState();
}

class _FloatingBackgroundState extends State<FloatingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<FloatingIconConfig> _icons;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _generateIcons();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  void _generateIcons() {
    final random = math.Random();
    final defaultIcons = widget.customIcons ?? _getDefaultIcons();

    _icons = List.generate(widget.iconCount, (index) {
      return FloatingIconConfig(
        icon: defaultIcons[index % defaultIcons.length],
        color: widget.primaryColor.withOpacity(0.6),
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: AppConstants.floatingIconMinSize +
            random.nextDouble() *
                (AppConstants.floatingIconMaxSize -
                    AppConstants.floatingIconMinSize),
        speed: 0.1 + random.nextDouble() * 0.15,
        delay: random.nextDouble(),
      );
    });
  }

  List<IconData> _getDefaultIcons() {
    return const [
      Icons.shopping_cart_outlined,
      Icons.favorite_outline,
      Icons.local_offer_outlined,
      Icons.card_giftcard_outlined,
      Icons.star_outline,
      Icons.shopping_bag_outlined,
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: _icons.map(_buildFloatingIcon).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(FloatingIconConfig config) {
    final screen = MediaQuery.of(context).size;
    final progress = (_controller.value + config.delay) % 1.0;
    final y = config.y + (progress * config.speed * 2) - config.speed;

    return Positioned(
      left: screen.width * config.x,
      top: 120 + (screen.height * 0.55 * (y % 1.0)),
      child: Opacity(
        opacity: widget.opacity,
        child: Transform.rotate(
          angle: progress * 2 * math.pi,
          child: Icon(
            config.icon,
            size: config.size,
            color: config.color,
          ),
        ),
      ),
    );
  }
}

/// Gradient background widget
///
/// Provides a subtle gradient background commonly used across the app
class GradientBackground extends StatelessWidget {
  final Color backgroundColor;
  final double opacity;

  const GradientBackground({
    Key? key,
    required this.backgroundColor,
    this.opacity = 0.05,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor.withOpacity(opacity),
            backgroundColor,
            backgroundColor.withOpacity(opacity),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

/// Complete animated page background
///
/// Combines gradient and floating icons for a complete page background
class AnimatedPageBackground extends StatelessWidget {
  final Color backgroundColor;
  final Color accentColor;
  final List<IconData>? customIcons;

  const AnimatedPageBackground({
    Key? key,
    required this.backgroundColor,
    required this.accentColor,
    this.customIcons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GradientBackground(backgroundColor: backgroundColor),
        FloatingBackground(
          primaryColor: accentColor,
          customIcons: customIcons,
        ),
      ],
    );
  }
}
