// lib/presentation/pages/wishlist/wishlist_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:anu_app/api/services/auth_service.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/core/models/wishlist_item_model.dart';
import 'package:anu_app/presentation/pages/shared/custom_bottom_nav.dart';
import 'package:anu_app/presentation/pages/shared/custom_app_bar.dart';
import 'package:anu_app/presentation/pages/wishlist/widgets/enhanced_wishlist_item_card.dart';
import 'package:anu_app/presentation/pages/wishlist/widgets/empty_wishlist.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late List<FloatingIcon> _floatingIcons;
  bool _isAuthError = false; // ✅ track session-expired scenario

  @override
  void initState() {
    super.initState();
    _initFloatingBackground();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadWishlist();
    });
  }

  bool _checkIsAuthError(String? msg) {
    if (msg == null) return false;
    final lower = msg.toLowerCase();
    return lower.contains('token') ||
        lower.contains('unauthorized') ||
        lower.contains('authentication') ||
        lower.contains('not authenticated') ||
        lower.contains('invalid') ||
        lower.contains('expired') ||
        lower.contains('login') ||
        lower.contains('401') ||
        lower.contains('403');
  }

  Future<void> _checkAuthAndLoadWishlist() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }

    await _loadWishlist();

    if (!mounted) return;

    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    if (wishlistProvider.errorMessage != null &&
        _checkIsAuthError(wishlistProvider.errorMessage)) {
      await authService.logout();
      if (mounted) context.go('/login');
    }
  }

  void _showLoginRequired() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.favorite_border,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Login Required',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please login to view and manage your wishlist.',
                  style: TextStyle(
                      fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWishlistBenefit('Save products you love'),
                      const SizedBox(height: 8),
                      _buildWishlistBenefit('Get price drop alerts'),
                      const SizedBox(height: 8),
                      _buildWishlistBenefit('Quick access to favorites'),
                      const SizedBox(height: 8),
                      _buildWishlistBenefit('Sync across devices'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/home');
                },
                style:
                    TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                child: const Text('Go to Home'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/login?redirect=/wishlist');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Login',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildWishlistBenefit(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: Colors.blue.shade600, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: Colors.black87))),
      ],
    );
  }

  void _initFloatingBackground() {
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    )..repeat();

    final icons = [
      Icons.favorite_outline,
      Icons.shopping_cart_outlined,
      Icons.local_offer_outlined,
      Icons.card_giftcard_outlined,
      Icons.star_outline,
    ];

    _floatingIcons = List.generate(10, (index) {
      return FloatingIcon(
        icon: icons[index % icons.length],
        color: AppTheme.primaryColor.withOpacity(0.6),
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 8 + 18,
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

  Future<void> _loadWishlist() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    await wishlistProvider.fetchWishlistItems();
  }

  Future<void> _refreshWishlist() async {
    setState(() => _isAuthError = false);
    await _checkAuthAndLoadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppTheme.isTablet(context);

    return WillPopScope(
      onWillPop: () async {
        if (context.canPop()) {
          context.pop();
        } else {
          context.push('/home');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: CustomAppBar(
          title: 'My Wishlist',
          onBackPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.push('/home');
            }
          },
          actions: _buildAppBarActions(),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.backgroundColor.withOpacity(0.05),
                    AppTheme.backgroundColor,
                    AppTheme.backgroundColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    final screen = MediaQuery.of(context).size;
                    return Stack(
                      children: _floatingIcons.map((icon) {
                        final progress =
                            (_floatingController.value + icon.delay) % 1.0;
                        final y =
                            icon.y + (progress * icon.speed * 2) - icon.speed;
                        return Positioned(
                          left: screen.width * icon.x,
                          top: 120 + (screen.height * 0.55 * (y % 1.0)),
                          child: Opacity(
                            opacity: 0.18,
                            child: Transform.rotate(
                              angle: progress * 2 * math.pi,
                              child: Icon(icon.icon,
                                  size: icon.size, color: icon.color),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),

            // ✅ Auth error takes priority
            if (_isAuthError)
              _buildSessionExpiredView()
            else
              Consumer<WishlistProvider>(
                builder: (context, wishlistProvider, child) {
                  // Check dynamically too
                  if (wishlistProvider.errorMessage != null &&
                      _checkIsAuthError(wishlistProvider.errorMessage)) {
                    return _buildSessionExpiredView();
                  }

                  if (wishlistProvider.isLoading) {
                    return _buildLoadingState();
                  }

                  if (wishlistProvider.errorMessage != null) {
                    return _buildErrorState(wishlistProvider.errorMessage!);
                  }

                  if (wishlistProvider.isEmpty) {
                    return const EmptyWishlist();
                  }

                  return _buildWishlistContent(
                      context, wishlistProvider, isTablet);
                },
              ),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      ),
    );
  }

  // ✅ Session expired view
  Widget _buildSessionExpiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_outlined,
                  size: 52, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Expired',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Your session has expired. Please login again to view your wishlist.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/login?redirect=/wishlist'),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Login Again',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          if (wishlistProvider.isEmpty || wishlistProvider.isLoading) {
            return const SizedBox.shrink();
          }
          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear_all') _showClearAllConfirmation(context);
              if (value == 'move_all_to_cart') _moveAllToCart();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'move_all_to_cart',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, size: 20),
                    SizedBox(width: 8),
                    Text('Move All to Cart'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Clear All',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildLoadingState() => const Center(child: LogoLoader());

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading wishlist',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshWishlist,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistContent(
      BuildContext context, WishlistProvider wishlistProvider, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _refreshWishlist,
      color: AppTheme.primaryColor,
      child: isTablet
          ? _buildGridLayout(wishlistProvider)
          : _buildListLayout(wishlistProvider),
    );
  }

  Widget _buildListLayout(WishlistProvider wishlistProvider) {
    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: wishlistProvider.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = wishlistProvider.wishlistItems[index];
        return EnhancedWishlistItemCard(
          item: item,
          onRemove: () => _showRemoveItemDialog(item),
          onAddToCart: () => _addToCart(item),
        );
      },
    );
  }

  Widget _buildGridLayout(WishlistProvider wishlistProvider) {
    return GridView.builder(
      padding: AppTheme.getResponsivePadding(context),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: wishlistProvider.wishlistItems.length,
      itemBuilder: (context, index) {
        final item = wishlistProvider.wishlistItems[index];
        return EnhancedWishlistItemCard(
          item: item,
          onRemove: () => _showRemoveItemDialog(item),
          onAddToCart: () => _addToCart(item),
        );
      },
    );
  }

  void _showRemoveItemDialog(WishlistItemModel item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Remove from Wishlist'),
          content: Text(
              'Are you sure you want to remove "${item.productInfo.name}" from your wishlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final wishlistProvider =
                    Provider.of<WishlistProvider>(context, listen: false);
                final success =
                    await wishlistProvider.removeFromWishlist(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? 'Removed from wishlist'
                        : 'Failed to remove item'),
                    backgroundColor:
                        success ? const Color(0xFFF96A4C) : Colors.red,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear Wishlist'),
          content: Text(
              'Are you sure you want to remove all ${wishlistProvider.wishlistCount} items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await wishlistProvider.clearWishlist();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success
                        ? 'Wishlist cleared successfully'
                        : 'Failed to clear wishlist'),
                    backgroundColor:
                        success ? const Color(0xFFF96A4C) : Colors.red,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToCart(WishlistItemModel item) async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final success = await wishlistProvider.addWishlistItemToCart(item);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Added to cart' : 'Failed to add to cart'),
        backgroundColor: success ? const Color(0xFF4CAF50) : Colors.red,
      ));
    }
  }

  Future<void> _moveAllToCart() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    int successCount = 0, failCount = 0;
    for (var item in wishlistProvider.wishlistItems) {
      final success = await wishlistProvider.moveToCart(item);
      if (success)
        successCount++;
      else
        failCount++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$successCount items moved to cart${failCount > 0 ? ', $failCount failed' : ''}'),
        backgroundColor:
            failCount == 0 ? const Color(0xFFF96A4C) : Colors.orange,
      ));
    }
  }
}

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
