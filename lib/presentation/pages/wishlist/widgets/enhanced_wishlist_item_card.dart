// lib/presentation/pages/wishlist/widgets/enhanced_wishlist_item_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/wishlist_item_model.dart';
import '../../../../core/models/mobile_variant_model.dart';
import '../../../../api/services/cart_image_service.dart';
import '../../../../api/services/product_service.dart';
import '../../../../config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class EnhancedWishlistItemCard extends StatefulWidget {
  final WishlistItemModel item;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const EnhancedWishlistItemCard({
    Key? key,
    required this.item,
    required this.onRemove,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<EnhancedWishlistItemCard> createState() =>
      _EnhancedWishlistItemCardState();
}

class _EnhancedWishlistItemCardState extends State<EnhancedWishlistItemCard> {
  final CartImageService _imageService = CartImageService();
  final ProductService _productService = ProductService();
  String? _variantImageUrl;
  bool _isLoadingImage = true;
  bool _isLoadingVariantInfo = true;
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedColorDisplay;

  @override
  void initState() {
    super.initState();
    _loadVariantImage();
    _loadVariantInfo();
  }

  Future<void> _loadVariantImage() async {
    if (widget.item.productInfo.slug.isNotEmpty) {
      final imageUrl = await _imageService.getCartItemImageUrl(
        widget.item.productInfo.slug,
        widget.item.variantId,
      );

      if (mounted) {
        setState(() {
          _variantImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } else {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _loadVariantInfo() async {
    if (widget.item.productInfo.slug.isNotEmpty &&
        widget.item.variantId != null) {
      try {
        final result = await _productService.getMobileVariantSelector(
          widget.item.productInfo.slug,
        );

        if (result['success'] && mounted) {
          final variantData = result['data'] as MobileVariantSelector;
          _extractVariantDetails(variantData);
        }
      } catch (e) {
        print('Error loading variant info: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingVariantInfo = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingVariantInfo = false;
      });
    }
  }

  void _extractVariantDetails(MobileVariantSelector variantData) {
    final variantIdInt = int.tryParse(widget.item.variantId ?? '');
    if (variantIdInt == null) return;

    // Find the matching variant by checking all color and size combinations
    for (final color in variantData.colors) {
      for (final size in color.availableSizes) {
        if (size.variantId == variantIdInt) {
          setState(() {
            _selectedColor = color.colorValue;
            _selectedColorDisplay = color.colorDisplay;
            _selectedSize = size.sizeValue;
          });
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final isTablet = screenWidth >= 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            AppTheme.getResponsiveHorizontalPadding(context).horizontal / 2,
        vertical: 6,
      ),
      child: Card(
        elevation: AppTheme.getCardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        ),
        child: InkWell(
          onTap: () {
            if (widget.item.productInfo.slug.isNotEmpty) {
              context.push('/product/${widget.item.productInfo.slug}');
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
          child: Padding(
            padding: AppTheme.getResponsiveCardPadding(context),
            child: isTablet
                ? _buildTabletLayout(isCompact)
                : _buildMobileLayout(isCompact),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isCompact) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(isCompact),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: _buildProductDetails(isCompact),
            ),
          ],
        ),
        if (!isCompact) const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {}, // ⛔ absorb tap
          child: _buildActionButtons(isCompact),
        )
      ],
    );
  }

  Widget _buildTabletLayout(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductImage(isCompact),
        SizedBox(width: isCompact ? 12 : 20),
        Expanded(
          flex: 3,
          child: _buildProductDetails(isCompact),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: _buildActionButtons(isCompact, isTablet: true),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(bool isCompact) {
    final double width =
        isCompact ? 100.0 : (AppTheme.isTablet(context) ? 140.0 : 120.0);
    final double height = width * 1.3; // ✅ 4:3 aspect ratio for better balance

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        child: _isLoadingImage ? _buildImageSkeleton() : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageSkeleton() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: const LogoLoader(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = _variantImageUrl ?? widget.item.productInfo.image;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildProductDetails(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Text(
          widget.item.productInfo.name,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: isCompact ? 4 : 6),

        // Brand and seller info
        _buildSellerInfo(isCompact),

        // Variant details
        _buildVariantDetails(isCompact),

        SizedBox(height: isCompact ? 8 : 10),

        // Price information
        _buildPriceInfo(isCompact),

        // Availability status
        _buildAvailabilityStatus(isCompact),
      ],
    );
  }

  Widget _buildSellerInfo(bool isCompact) {
    final brandName = widget.item.productInfo.brandName;
    final sellerBusinessName = widget.item.productInfo.sellerBusinessName;
    final sellerUsername = widget.item.productInfo.sellerUsername;

    if (brandName == null &&
        sellerBusinessName == null &&
        sellerUsername == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: isCompact ? 4 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand name
          if (brandName != null && brandName.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                brandName,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),

          // Seller info
          if (sellerBusinessName != null && sellerBusinessName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 4 : 6),
              child: Row(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: isCompact ? 12 : 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      sellerBusinessName,
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else if (sellerUsername != null && sellerUsername.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 4 : 6),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: isCompact ? 12 : 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'by $sellerUsername',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVariantDetails(bool isCompact) {
    if (_isLoadingVariantInfo) {
      return Padding(
        padding: EdgeInsets.only(top: isCompact ? 4 : 6),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: const LogoLoader(),
            ),
            const SizedBox(width: 6),
            Text(
              'Loading variant...',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedColor == null && _selectedSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: isCompact ? 4 : 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (_selectedColorDisplay != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isCompact ? 8 : 10,
                    height: isCompact ? 8 : 10,
                    decoration: BoxDecoration(
                      color: _getColorFromValue(_selectedColor!),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedColorDisplay!,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedSize != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 6 : 8,
                vertical: isCompact ? 2 : 3,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.straighten,
                    size: isCompact ? 10 : 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedSize!,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorFromValue(String colorValue) {
    switch (colorValue.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return const Color(0xFFF96A4C);
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _buildPriceInfo(bool isCompact) {
    if (!widget.item.productInfo.hasValidPrice) {
      return Padding(
        padding: EdgeInsets.only(top: isCompact ? 4 : 6),
        child: Text(
          'Price not available',
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 4 : 6),
      child: Row(
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Text(
              widget.item.productInfo.formattedPrice,
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (widget.item.productInfo.hasDiscount) ...[
            const SizedBox(width: 8),
            Text(
              widget.item.productInfo.formattedRegularPrice,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: AppTheme.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${widget.item.productInfo.discountPercentage.toStringAsFixed(0)}% OFF',
                style: TextStyle(
                  fontSize: isCompact ? 9 : 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus(bool isCompact) {
    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 4 : 6),
      child: Row(
        children: [
          Icon(
            widget.item.productInfo.isAvailable
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: isCompact ? 12 : 14,
            color: widget.item.productInfo.isAvailable
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
          const SizedBox(width: 4),
          Text(
            widget.item.productInfo.isAvailable ? 'In Stock' : 'Out of Stock',
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              color: widget.item.productInfo.isAvailable
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isCompact, {bool isTablet = false}) {
    return Container(
      padding: EdgeInsets.only(top: isCompact ? 8 : 12),
      child: isTablet
          ? Column(
              children: [
                _buildAddToCartButton(isCompact),
                SizedBox(height: isCompact ? 8 : 12),
                _buildRemoveButton(isCompact),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildAddToCartButton(isCompact)),
                const SizedBox(width: 12),
                _buildRemoveButton(isCompact),
              ],
            ),
    );
  }

  Widget _buildAddToCartButton(bool isCompact) {
    final isDisabled = !widget.item.productInfo.isAvailable ||
        !widget.item.productInfo.hasValidPrice;

    if (isDisabled) {
      return SizedBox(
        height: isCompact ? 36 : 40,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(
            Icons.shopping_cart_outlined,
            size: isCompact ? 16 : 18,
          ),
          label: Text(
            'Add to Cart',
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.grey.shade600,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isCompact ? 36 : 44,
      child: Ink(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onAddToCart,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: isCompact ? 16 : 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(bool isCompact) {
    return SizedBox(
      height: isCompact ? 36 : 40,
      width: isCompact ? 36 : 40,
      child: IconButton(
        onPressed: widget.onRemove,
        icon: Icon(
          Icons.delete_outline,
          size: isCompact ? 18 : 20,
          color: AppTheme.errorColor,
        ),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.errorColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
