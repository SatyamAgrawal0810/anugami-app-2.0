import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:anu_app/utils/app_notifications.dart';

class TrustBadgesWidget extends StatefulWidget {
  final double? minOrderValue;
  final List<TrustBadge>? customBadges;

  const TrustBadgesWidget({
    Key? key,
    this.minOrderValue = 500,
    this.customBadges,
  }) : super(key: key);

  @override
  State<TrustBadgesWidget> createState() => _TrustBadgesWidgetState();
}

class _TrustBadgesWidgetState extends State<TrustBadgesWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  List<TrustBadge> _badges = [];

  static const Color primaryOrange = Color(0xFFFFBB4E);
  static const Color accentPurple = Color(0xFFD03FC0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupBadges();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _pulseController.repeat(reverse: true);
    });
  }

  void _setupBadges() {
    _badges = widget.customBadges ??
        [
          TrustBadge(
            title: 'Free\nShipping',
            subtitle: 'On orders\nabove ₹999',
            icon: LucideIcons.truck,
            iconColor: primaryOrange,
            backgroundColor: Colors.white,
            borderColor: primaryOrange.withOpacity(0.15),
            isHighlighted: true,
          ),
          TrustBadge(
            title: '24 Hours\nCancel',
            subtitle: 'When\nOrdered',
            icon: LucideIcons.rotateCcw,
            iconColor: primaryOrange,
            backgroundColor: Colors.white,
            borderColor: primaryOrange.withOpacity(0.15),
          ),
          TrustBadge(
            title: '100%\nAuthentic',
            subtitle: 'Genuine\nproducts',
            icon: LucideIcons.shieldCheck,
            iconColor: primaryOrange,
            backgroundColor: Colors.white,
            borderColor: primaryOrange.withOpacity(0.15),
          ),
          TrustBadge(
            title: 'Contact\nUs',
            subtitle: 'Always here\nto help',
            icon: LucideIcons.headphones,
            iconColor: primaryOrange,
            backgroundColor: Colors.white,
            borderColor: primaryOrange.withOpacity(0.15),
          ),
        ];
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isCompact = screenWidth < 350;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isCompact),
              const SizedBox(height: 14),
              _buildBadgesGrid(screenWidth, isCompact),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Text(
      'Why Choose Us',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBadgesGrid(double screenWidth, bool isCompact) {
    return SizedBox(
      height: isCompact ? 170 : 190,
      child: Row(
        children: List.generate(_badges.length, (index) {
          return Expanded(
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.85 + (0.15 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildBadgeCard(_badges[index], isCompact),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBadgeCard(TrustBadge badge, bool isCompact) {
    return GestureDetector(
      onTap: () => _onBadgeTap(badge),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: badge.isHighlighted ? _pulseAnimation.value : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: isCompact ? 40 : 48,
                  height: isCompact ? 40 : 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryOrange, accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    badge.icon,
                    color: Colors.white,
                    size: isCompact ? 20 : 24,
                  ),
                ),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[800],
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
                Text(
                  badge.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCompact ? 9.5 : 11,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onBadgeTap(TrustBadge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(badge.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${badge.title.replaceAll('\n', ' ')} → ${badge.subtitle.replaceAll('\n', ' ')}",
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: primaryOrange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}

class TrustBadge {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool isHighlighted;

  TrustBadge({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.isHighlighted = false,
  });
}
