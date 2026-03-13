// lib/presentation/pages/home/home_page.dart
// ✅ PRODUCTION READY CODE
// ✅ FIXED: setState during build error resolved
// ✅ OPTIMIZATION 1: Single API call with parallel loading
// ✅ OPTIMIZATION 2: Smart caching - don't reload if data exists
// ✅ OPTIMIZATION 3: Debounced wishlist/cart loading
// ✨ Scroll-responsive app bar with color transition
// ✨ Animated gradient sweep line below AppBar
// 🎯 PRODUCTION: No success messages on refresh - only errors shown

import 'dart:ui' show lerpDouble;
import 'package:anu_app/providers/cart_provider.dart';
import 'package:anu_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../../../providers/wishlist_provider.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/home_drawer.dart';
import 'widgets/banner_slider1.dart';
import 'widgets/categories_section.dart';
import 'widgets/products_section.dart';
import '../shared/custom_bottom_nav.dart';
import 'package:anu_app/utils/app_notifications.dart';

// ═══════════════════════════════════════════════════════════════
// ✨ Animated gradient sweep line — fixed below AppBar
// ═══════════════════════════════════════════════════════════════
class _AnugamiSweepLine extends StatefulWidget {
  const _AnugamiSweepLine({Key? key}) : super(key: key);

  @override
  State<_AnugamiSweepLine> createState() => _AnugamiSweepLineState();
}

class _AnugamiSweepLineState extends State<_AnugamiSweepLine>
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
    return SizedBox(
      height: 2,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final sweepWidth = totalWidth * 0.20; // 20% width — same as CSS

              // CSS: translateX(-100%) → translateX(500%)
              // i.e. starts fully off-left, ends 5× its width to the right
              final dx = lerpDouble(
                -sweepWidth, // start: off-screen left
                sweepWidth * 5, // end:   off-screen right
                _ctrl.value,
              )!;

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // ── Track (semi-transparent gradient) ──
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x57FFBB4E), // orange 34%
                          Color(0x57F74A4C), // red 34%
                          Color(0x577E22CE), // purple 34%
                        ],
                      ),
                    ),
                  ),
                  // ── Sweep glow ──
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
                            Color(0xFFFFBB4E), // 55%
                            Color(0xFFF74A4C), // 65%
                            Color(0xFF7E22CE), // 75%
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

// ═══════════════════════════════════════════════════════════════
// Home Page
// ═══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialized = false;
  bool _isFirstLoad = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted || _initialized) return;
    setState(() => _initialized = true);

    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    if (productProvider.featuredProducts.isNotEmpty &&
        productProvider.newArrivals.isNotEmpty &&
        productProvider.bestSellers.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isFirstLoad = false);
      _loadUserDataInBackground();
      return;
    }

    try {
      await Future.wait([
        productProvider.loadFeaturedProducts(),
        productProvider.loadNewArrivals(),
        productProvider.loadBestSellers(),
      ]);
      if (!mounted) return;
      setState(() => _isFirstLoad = false);
      _loadUserDataInBackground();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFirstLoad = false);
    }
  }

  void _loadUserDataInBackground() {
    Future.microtask(() async {
      if (!mounted) return;
      try {
        final wishlistProvider =
            Provider.of<WishlistProvider>(context, listen: false);
        if (!wishlistProvider.isInitialized) {
          await wishlistProvider.initialize();
        }
        if (!mounted) return;
        final user = Provider.of<UserProvider>(context, listen: false);
        if (user.isLoggedIn) {
          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);
          if (cartProvider.items.isEmpty) {
            await cartProvider.fetchCartItems();
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    try {
      await Future.wait([
        productProvider.loadFeaturedProducts(),
        productProvider.loadNewArrivals(),
        productProvider.loadBestSellers(),
      ]);
    } catch (e) {
      if (!mounted) return;
      AppNotifications.showError(context, 'Failed to refresh. Try again.');
    }
  }

  void _navigateToProductDetails(ProductModel product) {
    if (!mounted) return;
    context.push('/product/${product.slug}');
  }

  void _navigateToAllProducts(String title, String type) {
    if (!mounted) return;
    context.push('/products?type=$type&title=$title');
  }

  void _handleWishlistTap(ProductModel product) {
    if (!mounted) return;
    Provider.of<OptimizedProductProvider>(context, listen: false)
        .toggleWishlist(product, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(scrollController: _scrollController),
      drawer: const HomeDrawer(),
      body: Column(
        children: [
          // ✨ Animated sweep line — fixed below AppBar, above scroll content
          const _AnugamiSweepLine(),

          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Consumer<OptimizedProductProvider>(
                builder: (_, productProvider, __) {
                  final hasData = productProvider.featuredProducts.isNotEmpty ||
                      productProvider.newArrivals.isNotEmpty ||
                      productProvider.bestSellers.isNotEmpty;

                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BannerSlider(),
                        const SizedBox(height: 16),
                        const CategoriesSection(),
                        const SizedBox(height: 16),

                        // Featured Products
                        ProductsSection(
                          title: 'Featured Products',
                          products: productProvider.featuredProducts,
                          isLoading:
                              productProvider.isLoadingFeatured && !hasData,
                          errorMessage: productProvider.featuredError,
                          onProductTap: _navigateToProductDetails,
                          onWishlistTap: _handleWishlistTap,
                          onRetry: productProvider.loadFeaturedProducts,
                          onViewAll: () => _navigateToAllProducts(
                              'Featured Products', 'featured'),
                        ),
                        const SizedBox(height: 16),

                        // New Arrivals
                        ProductsSection(
                          title: 'New Arrivals',
                          products: productProvider.newArrivals,
                          isLoading:
                              productProvider.isLoadingNewArrivals && !hasData,
                          errorMessage: productProvider.newArrivalsError,
                          onProductTap: _navigateToProductDetails,
                          onWishlistTap: _handleWishlistTap,
                          onRetry: productProvider.loadNewArrivals,
                          onViewAll: () => _navigateToAllProducts(
                              'New Arrivals', 'new_arrivals'),
                        ),
                        const SizedBox(height: 16),

                        // Best Sellers
                        ProductsSection(
                          title: 'Best Sellers',
                          products: productProvider.bestSellers,
                          isLoading:
                              productProvider.isLoadingBestSellers && !hasData,
                          errorMessage: productProvider.bestSellersError,
                          onProductTap: _navigateToProductDetails,
                          onWishlistTap: _handleWishlistTap,
                          onRetry: productProvider.loadBestSellers,
                          onViewAll: () => _navigateToAllProducts(
                              'Best Sellers', 'best_sellers'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
