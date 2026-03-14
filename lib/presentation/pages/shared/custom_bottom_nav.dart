// lib/presentation/pages/shared/custom_bottom_nav.dart
// ✅ FIXED: Bottom nav always visible with SafeArea
// ✨ UPDATED: Blended with home screen warm cream/orange theme

import 'package:anu_app/providers/cart_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _previousIndex = 0;

  static const Color _brandColor = Color(0xFFF96A4C);

  // ✨ Home screen background colors for blending
  static const Color _navBgTop =
      Color(0xFFFFF3EC); // warm cream — matches home bg
  static const Color _navBgBottom = Color(0xFFFFF8F5); // home scaffold bg

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _safeCurrentIndex {
    const int totalItems = 5;
    if (widget.currentIndex < 0 || widget.currentIndex >= totalItems) {
      return 0;
    }
    return widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CartProvider, WishlistProvider>(
      builder: (context, cartProvider, wishlistProvider, child) {
        return SafeArea(
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              // ✨ Warm gradient instead of flat white — blends with home screen
              gradient: const LinearGradient(
                colors: [_navBgTop, _navBgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                // ✨ Soft orange-tinted top shadow instead of harsh black
                BoxShadow(
                  color: const Color(0xFFF96A4C).withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home, null),
                _buildNavItem(1, Icons.category, null),
                _buildNavItem(2, Icons.shopping_cart, cartProvider.itemCount),
                _buildNavItem(
                    3, Icons.favorite, wishlistProvider.wishlistCount),
                _buildNavItem(4, Icons.person, null),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, int? badgeCount) {
    final isSelected = _safeCurrentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final slideOffset = isSelected
                ? Offset(
                    (_safeCurrentIndex - _previousIndex) *
                        0.3 *
                        (1 - _slideAnimation.value),
                    0,
                  )
                : Offset.zero;

            return Transform.translate(
              offset: slideOffset,
              child: Transform.scale(
                scale: isSelected ? _scaleAnimation.value : 1.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // ✨ Active indicator: gradient circle (unchanged)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      width: isSelected ? 50 : 0,
                      height: isSelected ? 50 : 0,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFFFEAF4E),
                                  Color(0xFFF96A4C),
                                  Color(0xFFE54481),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _brandColor.withOpacity(0.30),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),

                    // ✨ Icon — inactive icons use warm brown instead of harsh black
                    if (index == 0)
                      Image.asset(
                        'assets/images/loader1.png',
                        width: isSelected ? 40 : 35,
                        height: isSelected ? 40 : 35,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF7A4F3A), // warm brown
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.home,
                            size: isSelected ? 26 : 24,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF7A4F3A),
                          );
                        },
                      )
                    else
                      Icon(
                        icon,
                        size: isSelected ? 26 : 24,
                        // ✨ Inactive: warm brown; active: white
                        color:
                            isSelected ? Colors.white : const Color(0xFF7A4F3A),
                      ),

                    // Badge
                    if (badgeCount != null && badgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context) {
    try {
      switch (index) {
        case 0:
          context.push('/home');
          break;
        case 1:
          context.push('/categories');
          break;
        case 2:
          context.push('/cart');
          break;
        case 3:
          context.push('/wishlist');
          break;
        case 4:
          context.push('/profile');
          break;
        default:
          context.push('/home');
          break;
      }
    } catch (e) {
      debugPrint('❌ Navigation error: $e');
      context.push('/home');
    }
  }
}

class BottomNavIndex {
  static const int home = 0;
  static const int categories = 1;
  static const int cart = 2;
  static const int wishlist = 3;
  static const int profile = 4;

  static bool isValid(int index) => index >= 0 && index <= profile;
  static int getSafe(int index) => isValid(index) ? index : home;

  static int getByRoute(String route) {
    switch (route) {
      case '/home':
        return home;
      case '/categories':
        return categories;
      case '/cart':
        return cart;
      case '/wishlist':
        return wishlist;
      case '/profile':
        return profile;
      default:
        return home;
    }
  }
}