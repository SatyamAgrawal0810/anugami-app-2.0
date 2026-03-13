import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../../providers/wishlist_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final Function(ProductModel)? onWishlistTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    this.onWishlistTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  bool _isAddingToCart = false;
  bool _imageLoadError = false;
  bool _isImageLoading = true;

  @override
  void dispose() {
    super.dispose();
  }

  bool _isAddToCartEnabled() => widget.product.stockQuantity > 0;

  Future<void> _addToCart() async {
    if (!_isAddToCartEnabled() || _isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      await cartProvider.addItem(
        widget.product,
        quantity: 1,
        price: double.tryParse(widget.product.salePrice) ??
            double.tryParse(widget.product.regularPrice) ??
            0.0,
      );

      if (mounted) {
        AppNotifications.showSuccess(context, 'Success message');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to add to cart')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      debugPrint('❌ Add to cart error: $e');
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _incrementQuantity(CartProvider cartProvider) async {
    final productId = widget.product.id.toString();
    try {
      final cartItem = cartProvider.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );
      await cartProvider.incrementQuantity(cartItem.id);
    } catch (e) {
      debugPrint('❌ Increment quantity error: $e');
    }
  }

  Future<void> _decrementQuantity(CartProvider cartProvider) async {
    final productId = widget.product.id.toString();
    try {
      final cartItem = cartProvider.items.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found'),
      );
      await cartProvider.decrementQuantity(cartItem.id);
    } catch (e) {
      debugPrint('❌ Decrement quantity error: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    final wishlistProvider =
        Provider.of<WishlistProvider>(context, listen: false);
    final productId = widget.product.id.toString();

    try {
      final success = await wishlistProvider.toggleWishlist(productId);

      if (mounted && success) {
        final isWishlisted = wishlistProvider.isInWishlist(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isWishlisted
                        ? '${widget.product.name} added to wishlist!'
                        : '${widget.product.name} removed from wishlist',
                  ),
                ),
              ],
            ),
            backgroundColor:
                isWishlisted ? const Color(0xFFF96A4C) : Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Wishlist toggle error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update wishlist'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildProductImage() {
    if (_imageLoadError || widget.product.primaryImageUrl.isEmpty) {
      return Container(
        height: 110,
        width: double.infinity,
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text('No Image',
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Image.network(
          widget.product.primaryImageUrl,
          height: 110,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              if (_isImageLoading && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isImageLoading = false);
                });
              }
              return child;
            }
            return Container(
              height: 110,
              width: double.infinity,
              color: Colors.grey[100],
              child: const Center(
                child: SizedBox(width: 24, height: 24, child: LogoLoader()),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            if (!_imageLoadError && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _imageLoadError = true;
                    _isImageLoading = false;
                  });
                }
              });
            }
            return Container(
              height: 110,
              width: double.infinity,
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text('Load Failed',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Quantity stepper shown after item is in cart
  Widget _buildQuantityStepper(CartProvider cartProvider, int currentQty) {
    return SizedBox(
      width: double.infinity,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // — button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _decrementQuantity(cartProvider),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.remove, color: Colors.white, size: 14),
                ),
              ),
            ),

            // count
            Text(
              '$currentQty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            // + button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _incrementQuantity(cartProvider),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 165,
        height: 250,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            // ================= IMAGE =================
            SizedBox(
              height: 110,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: _buildProductImage(),
                  ),

                  // ❤️ Wishlist Button
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, _) {
                        final productId = product.id.toString();
                        final isWishlisted =
                            wishlistProvider.isInWishlist(productId);
                        final isLoading = wishlistProvider.isLoading;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoading ? null : _toggleWishlist,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(
                                      isWishlisted
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isWishlisted
                                          ? const Color(0xFFFF4947)
                                          : Colors.grey,
                                      size: 16,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ================= CONTENT =================
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Price
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => AppTheme
                                    .primaryGradient
                                    .createShader(bounds),
                                child: Text(
                                  product.formattedSalePrice,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (product.discountPercentage.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        product.formattedRegularPrice,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${product.discountPercentage.replaceAll('%', '')}% OFF",
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Stock + Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              product.stockQuantity > 0
                                  ? Icons.check_circle
                                  : Icons.error,
                              size: 10,
                              color: product.stockQuantity > 0
                                  ? const Color(0xFFF96A4C)
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.stockQuantity > 0
                                    ? 'In Stock'
                                    : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: product.stockQuantity > 0
                                      ? const Color(0xFFF96A4C)
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            final productId = product.id.toString();
                            final inCart =
                                cartProvider.isProductInCart(productId);
                            final qty =
                                cartProvider.getProductQuantity(productId);

                            if (!_isAddToCartEnabled()) {
                              return Container(
                                width: double.infinity,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.block,
                                          color: Colors.grey, size: 10),
                                      SizedBox(width: 4),
                                      Text(
                                        'Out of Stock',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (inCart && qty > 0) {
                              return _buildQuantityStepper(cartProvider, qty);
                            }

                            // Add to Cart button
                            return SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isAddingToCart ? null : _addToCart,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: _isAddingToCart
                                          ? LinearGradient(colors: [
                                              Colors.grey.shade400,
                                              Colors.grey.shade500,
                                            ])
                                          : AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: _isAddingToCart
                                          ? const SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.shopping_cart_outlined,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Add to Cart',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
