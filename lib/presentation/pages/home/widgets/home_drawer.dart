// lib/presentation/pages/home/widgets/home_drawer.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/utils/app_notifications.dart';
import '../../../../providers/user_provider.dart';
import '../../profile/my_addresses_page.dart';
import 'drawer_item.dart';
import 'package:anu_app/config/theme.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({Key? key}) : super(key: key);

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  late List<FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    _floatingIcons = _generateFloatingIcons();
  }

  List<FloatingIcon> _generateFloatingIcons() {
    final icons = [
      Icons.home_outlined,
      Icons.shopping_cart_outlined,
      Icons.favorite_outline,
      Icons.category_outlined,
      Icons.person_outline,
      Icons.settings_outlined,
    ];

    return List.generate(10, (index) {
      return FloatingIcon(
        icon: icons[index % icons.length],
        color: AppTheme.primaryColor.withOpacity(0.4),
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 6 + 14,
        speed: math.Random().nextDouble() * 0.25 + 0.1,
        delay: math.Random().nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;
    final fullName = userProvider.fullName;
    final email = userProvider.email;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.65, // 👈 width reduced
      child: Drawer(
        child: Stack(
          children: [
            // 🌈 Floating icons background (Home → Logout)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    final size = MediaQuery.of(context).size;

                    return Stack(
                      children: _floatingIcons.map((icon) {
                        final progress =
                            (_floatingController.value + icon.delay) % 1.0;
                        final y =
                            icon.y + (progress * icon.speed * 2) - icon.speed;

                        return Positioned(
                          left: size.width * 0.7 * icon.x,
                          top: 160 + (size.height * 0.6 * (y % 1.0)),
                          child: Opacity(
                            opacity: 0.18,
                            child: Transform.rotate(
                              angle: progress * 2 * math.pi,
                              child: Icon(
                                icon.icon,
                                size: icon.size,
                                color: icon.color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),

            // 🧱 Foreground Drawer content
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // ================= HEADER =================
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Stack(
                    children: [
                      // ✨ Dot pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DotPatternPainter(),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) =>
                                  AppTheme.primaryGradient.createShader(bounds),
                              child: const Icon(
                                Icons.person,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isLoggedIn
                                ? 'Welcome, $fullName'
                                : 'Welcome, Guest',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLoggedIn && email.isNotEmpty
                                ? email
                                : 'Sign in to continue',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================= ITEMS =================
                DrawerItem(
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/home');
                    }),
                DrawerItem(
                    icon: Icons.category,
                    title: 'Categories',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/categories');
                    }),
                DrawerItem(
                    icon: Icons.shopping_bag,
                    title: 'My Orders',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/orders');
                    }),
                DrawerItem(
                    icon: Icons.favorite,
                    title: 'Wishlist',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/wishlist');
                    }),
                DrawerItem(
                    icon: Icons.person,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    }),
                DrawerItem(
                    icon: Icons.location_on,
                    title: 'My Addresses',
                    onTap: () {
                      Navigator.pop(context);
                      if (!isLoggedIn) {
                        AppNotifications.showError(context, 'Error message');
                        context.push('/login');
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAddressesPage(),
                        ),
                      );
                    }),
                const Divider(),
                DrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    }),
                DrawerItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/profile');
                    }),
                isLoggedIn
                    ? DrawerItem(
                        icon: Icons.exit_to_app,
                        title: 'Logout',
                        onTap: () async {
                          Navigator.pop(context);
                          await userProvider.logout();
                          if (context.mounted) {
                            context.push('/login');
                          }
                        },
                      )
                    : DrawerItem(
                        icon: Icons.login,
                        title: 'Login',
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/login');
                        },
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= FLOATING ICON MODEL =================

class FloatingIcon {
  final IconData icon;
  final Color color;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

  FloatingIcon({
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

// ================= DOT PATTERN =================

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    const double radius = 3;
    const double gap = 26;

    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
