// lib/presentation/pages/home/widgets/home_app_bar.dart
// ✨ Scroll-Responsive App Bar with Brand Color Transition

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
  double _scrollOffset = 0.0;

  // 🔄 Rotating search suggestions
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

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
    _startSuggestionRotation();

    // Scroll listener
    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = widget.scrollController?.offset ?? 0.0;
      });
    }
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
    widget.scrollController?.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  // 🎨 Calculate gradient colors based on scroll
  List<Color> _getGradientColors() {
    // Scroll progress: 0 (top) to 1.0 (scrolled 150px)
    final double progress = (_scrollOffset / 150).clamp(0.0, 1.0);

    // Get colors from AppTheme.primaryGradient
    final gradientColors = AppTheme.primaryGradient.colors;

    // Interpolate each gradient color to background color
    return gradientColors.map((color) {
      return Color.lerp(color, AppTheme.backgroundColor, progress)!;
    }).toList();
  }

  // 🎨 Calculate logo opacity based on scroll
  double _getLogoOpacity() {
    // Only fade white logo slightly for smooth transition
    // Colored logo stays at full opacity
    if (_shouldShowWhiteLogo()) {
      // White logo: fade from 1.0 to 0.7 as you scroll
      final double progress = (_scrollOffset / 75).clamp(0.0, 1.0);
      return 1.0 - (progress * 0.3); // Fades to 70% opacity
    } else {
      // Colored logo: FULL OPACITY - no fade
      return 1.0; // Always 100% opacity
    }
  }

  // 📏 Calculate logo scale based on scroll
  double _getLogoScale() {
    if (_shouldShowWhiteLogo()) {
      // White logo: shrinks gradually
      final double progress = (_scrollOffset / 75).clamp(0.0, 1.0);
      return 1.0 - (progress * 0.1); // Shrinks to 90%
    } else {
      // Colored logo: stays larger, minimal shrink
      final double progress = ((_scrollOffset - 75) / 75).clamp(0.0, 1.0);
      return 1.0 - (progress * 0.05); // Only shrinks to 95% (stays bigger)
    }
  }

  // 🔄 Decide which logo to show based on scroll
  bool _shouldShowWhiteLogo() {
    // Show white logo when background is dark (not scrolled much)
    // Switch to colored logo at halfway point (75px)
    return _scrollOffset < 75;
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final logoOpacity = _getLogoOpacity();
    final logoScale = _getLogoScale();
    final showWhiteLogo = _shouldShowWhiteLogo();

    return Container(
      // ✨ Dynamic gradient background (transitions on scroll)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AppTheme.primaryGradient.begin,
          end: AppTheme.primaryGradient.end,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            children: [
              // 🏷️ Logo with Dynamic Color Swap + Fade + Scale
              AnimatedOpacity(
                opacity: logoOpacity,
                duration: const Duration(milliseconds: 100),
                child: Transform.scale(
                  scale: logoScale,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      showWhiteLogo
                          ? 'assets/images/icon1.png' // White logo for dark background
                          : 'assets/images/app_icon.png', // Colored logo for light background
                      key: ValueKey<bool>(showWhiteLogo),
                      height: 75,
                      width: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 🔍 Search Bar
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push('/search');
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        // Primary color shadow
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                        // Subtle black shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),

                        // Search icon
                        Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),

                        const SizedBox(width: 12),

                        // Animated suggestion text
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                _searchSuggestions[_currentSuggestionIndex],
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Divider line
                        Container(
                          width: 1,
                          height: 28,
                          color: AppTheme.dividerColor,
                        ),

                        const SizedBox(width: 12),

                        // Voice icon
                        Icon(
                          Icons.mic_none_rounded,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),

                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
