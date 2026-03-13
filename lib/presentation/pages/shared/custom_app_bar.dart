// lib/presentation/pages/shared/custom_app_bar.dart

import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Blended white color applied globally to all icons & text via IconTheme
    const blendedWhite = Color(0xEBFFFFFF); // white at ~92% opacity
    const iconShadows = [
      Shadow(color: Color(0x4D000000), blurRadius: 8),
    ];

    return IconTheme(
      data: const IconThemeData(
        color: blendedWhite,
        shadows: iconShadows,
      ),
      child: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        foregroundColor: blendedWhite, // tints AppBar-managed icons/text

        // ── Background: image + subtle dark overlay for text readability ──
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/appbar_bg.png',
              fit: BoxFit.cover,
            ),
            // soft dark overlay so white text blends naturally
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ],
        ),

        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),

        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white.withOpacity(0.92),
                  shadows: const [
                    Shadow(color: Color(0x4D000000), blurRadius: 6),
                  ],
                ),
                onPressed: widget.onBackPressed ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.push('/home');
                      }
                    },
              )
            : null,

        // Actions: if caller passes custom widgets they're wrapped in IconTheme
        // above so their icons auto-blend; default search icon also blended
        actions: widget.actions ??
            [
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.92),
                  shadows: const [
                    Shadow(color: Color(0x4D000000), blurRadius: 6),
                  ],
                ),
                onPressed: () {},
              ),
            ],

        // ── Sweep line ───────────────────────────────────────────────────────
        bottom: _SweepLineBottom(ctrl: _ctrl),
      ),
    );
  }
}

// ─── Sweep line attached to AppBar.bottom ─────────────────────────────────────
class _SweepLineBottom extends StatelessWidget implements PreferredSizeWidget {
  const _SweepLineBottom({required this.ctrl});

  final AnimationController ctrl;

  @override
  Size get preferredSize => const Size.fromHeight(2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final sweepWidth = totalWidth * 0.20;

              // CSS: translateX(-100%) → translateX(500%)
              final dx = lerpDouble(
                -sweepWidth,
                sweepWidth * 5,
                ctrl.value,
              )!;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Track
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x57FFBB4E),
                          Color(0x57F74A4C),
                          Color(0x577E22CE),
                        ],
                      ),
                    ),
                  ),

                  // Sweeper
                  Transform.translate(
                    offset: Offset(dx, 0),
                    child: Container(
                      width: sweepWidth,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFFFBB4E),
                            Color(0xFFF74A4C),
                            Color(0xFF7E22CE),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.35, 0.50, 0.65, 1.0],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x99F74A4C),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// 🎨 Subtle AppBar background pattern — kept for reference, not used
class AppBarPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
