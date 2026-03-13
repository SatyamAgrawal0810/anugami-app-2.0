// lib/presentation/pages/cart/cart_page.dart
import 'dart:math' as math;
import 'package:anu_app/presentation/pages/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import '../../../providers/cart_provider.dart';
import '../../../config/theme.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/enhanced_cart_item_card.dart';
import 'widgets/cart_summary_card.dart';
import 'widgets/empty_cart.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late List<FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();

    Future.microtask(() =>
        Provider.of<CartProvider>(context, listen: false).fetchCartItems());

    _initFloatingBackground();
  }

  void _initFloatingBackground() {
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    final icons = [
      Icons.shopping_cart_outlined,
      Icons.local_offer_outlined,
      Icons.favorite_outline,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'My Cart',
        showBackButton: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearCartDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient bg
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

          // Floating icons
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

          // Cart UI
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isLoading) {
                return const Center(child: LogoLoader());
              }
              if (cartProvider.error != null) {
                return _buildErrorView(cartProvider.error!);
              }
              if (cartProvider.items.isEmpty) {
                return const EmptyCart();
              }
              return _buildCartContent(context, cartProvider, isTablet);
            },
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildCartContent(
      BuildContext context, CartProvider cartProvider, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet && constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildCartList(cartProvider)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildStickyCartSummary(cartProvider)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSelectionBar(cartProvider),
              Expanded(child: _buildCartList(cartProvider)),
              _buildBottomSummary(cartProvider),
            ],
          );
        }
      },
    );
  }

  Widget _buildSelectionBar(CartProvider cartProvider) {
    final selected = cartProvider.selectedCount;
    final total = cartProvider.itemCount;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (cartProvider.allSelected) {
                cartProvider.deselectAll();
              } else {
                cartProvider.selectAll();
              }
            },
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cartProvider.allSelected
                        ? AppTheme.primaryColor
                        : Colors.white,
                    border: Border.all(
                      color: cartProvider.allSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: cartProvider.allSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : cartProvider.selectedCount > 0
                          ? Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cartProvider.allSelected
                        ? AppTheme.primaryColor
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$selected of $total items selected',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          if (selected > 0)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: Text(
                '₹${cartProvider.finalTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartList(CartProvider cartProvider) {
    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: cartProvider.items.length,
      itemBuilder: (context, index) {
        final item = cartProvider.items[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          // ✅ Premium glow wrapper reacts to selection state
          child: _GlowWrapper(
            isSelected: cartProvider.isSelected(item.id),
            child: EnhancedCartItemCard(
              key: ValueKey(item.id),
              item: item,
              onIncrement: () => cartProvider.incrementQuantity(item.id),
              onDecrement: () => cartProvider.decrementQuantity(item.id),
              onRemove: () =>
                  _showRemoveItemDialog(context, item.id, cartProvider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickyCartSummary(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CartSummaryCard(
        cartProvider: cartProvider,
        onCheckout: () => context.push('/checkout'),
      ),
    );
  }

  Widget _buildBottomSummary(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CartSummaryCard(
            cartProvider: cartProvider,
            onCheckout: () => context.push('/checkout'),
            isCompact: true,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
          const SizedBox(height: 16),
          Text('Error loading cart',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Provider.of<CartProvider>(context, listen: false)
                .fetchCartItems(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(
      BuildContext context, int itemId, CartProvider cartProvider) {
    final item = cartProvider.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => cartProvider.items.first,
    );

    debugPrint('🗑️ Remove dialog opened for item: ${item.name} (ID: $itemId)');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Remove Item'),
          content: Text('Remove "${item.name}" from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint('✅ Removing item: ${item.name} (ID: $itemId)');
                Navigator.of(dialogContext).pop();
                cartProvider.removeItem(itemId);
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

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear Cart'),
          content: const Text(
              'Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Provider.of<CartProvider>(context, listen: false).clearCart();
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
}

// ─── Glow Wrapper ─────────────────────────────────────────────────────────────
/// Wraps a cart item card with an animated gradient glow when selected.
/// Uses [AnimatedContainer] so the transition in/out is smooth (300 ms).
class _GlowWrapper extends StatelessWidget {
  const _GlowWrapper({
    required this.isSelected,
    required this.child,
  });

  final bool isSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glowColor = AppTheme.primaryGradient.colors.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.08),
                  blurRadius: 15,
                  offset: Offset.zero,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────
class FloatingIcon {
  final IconData icon;
  final Color color;
  final double x, y, size, speed, delay;

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
