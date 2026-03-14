// lib/presentation/pages/home/widgets/home_app_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';

class HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ScrollController? scrollController;

  const HomeAppBar({
    Key? key,
    this.scrollController,
  }) : super(key: key);

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

class _HomeAppBarState extends State<HomeAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentSuggestionIndex = 0;

  final List<String> _searchSuggestions = [
    'Search "Mascara"',
    'Search "Night Cream"',
    'Search "Smartphones"',
    'Search "Laptops"',
    'Search "Headphones"',
    'Search "Joggers"',
    'Search "Dresses"',
    'Search "Camera"',
    'Search "Gaming"',
    'Search "Accessories"',
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _startSuggestionRotation();
  }

  void _startSuggestionRotation() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentSuggestionIndex =
                  (_currentSuggestionIndex + 1) % _searchSuggestions.length;
            });
            _animationController.forward();
            _startSuggestionRotation();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Fixed PNG background ──────────────────────────────────────
        Positioned.fill(
          child: Image.asset(
            'assets/images/appbar_bg.png',
            fit: BoxFit.cover,
          ),
        ),

        // ── 2. Content ───────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                // 🏷️ Fixed Logo — no scroll effect
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 75,
                  width: 60,
                  fit: BoxFit.contain,
                ),

                const SizedBox(width: 12),

                // 🔍 Search Bar
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            // ✨ Slightly more opaque for gradient text contrast
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(.08),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.85),
                                size: 24,
                              ),
                              const SizedBox(width: 12),

                              // ✨ Gradient animated search suggestion
                              Expanded(
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFFFEAF4E), // warm gold
                                          Color(0xFFF96A4C), // brand orange
                                          Color(0xFFE54481), // pink
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ).createShader(bounds),
                                      blendMode: BlendMode.srcIn,
                                      child: Text(
                                        _searchSuggestions[
                                            _currentSuggestionIndex],
                                        style: const TextStyle(
                                          // ShaderMask overrides this with gradient
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),
                              Container(
                                width: 1,
                                height: 28,
                                color: Colors.white.withOpacity(0.20),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.mic_none_rounded,
                                color: Colors.white.withOpacity(0.85),
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}