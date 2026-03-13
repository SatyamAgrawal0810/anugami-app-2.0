// lib/presentation/pages/cart/widgets/enhanced_cart_item_card.dart
// ✅ 3 BUGS FIXED:
//   1. color.colorValue (undefined) → _selectedColor! in _buildVariantSection
//   2. _parseColor() removed from _EnhancedCartItemCardState
//   3. _parseColor() removed from _VariantChangeSheetState → AppColorUtils.parse()
// ✅ loop variable renamed: color → colorOpt (no naming conflict with Color type)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/mobile_variant_model.dart';
import '../../../../api/services/cart_image_service.dart';
import '../../../../api/services/product_service.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:anu_app/utils/color_utils.dart';

class EnhancedCartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const EnhancedCartItemCard({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<EnhancedCartItemCard> createState() => _EnhancedCartItemCardState();
}

class _EnhancedCartItemCardState extends State<EnhancedCartItemCard> {
  final CartImageService _imageService = CartImageService();
  final ProductService _productService = ProductService();

  String? _variantImageUrl;
  bool _isLoadingImage = true;
  bool _isLoadingVariantInfo = true;

  String? _selectedSize;
  String? _selectedColor;
  String? _selectedColorDisplay;
  MobileVariantSelector? _variantData;

  String? _fetchedBrandName;
  String? _fetchedSellerBusinessName;
  String? _fetchedSellerUsername;

  @override
  void initState() {
    super.initState();
    _loadVariantImage();
    _loadVariantInfo();
  }

  Future<void> _loadVariantImage() async {
    if (widget.item.productInfo?.slug != null) {
      final imageUrl = await _imageService.getCartItemImageUrl(
        widget.item.productInfo!.slug,
        widget.item.variantId,
      );
      if (mounted) {
        setState(() {
          _variantImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _loadVariantInfo() async {
    if (widget.item.productInfo?.slug != null) {
      try {
        final result = await _productService.getMobileVariantSelector(
          widget.item.productInfo!.slug,
        );
        if (result['success'] && mounted) {
          final data = result['data'] as MobileVariantSelector;
          _variantData = data;
          _extractSellerInfo(data);
          if (widget.item.variantId != null) _extractVariantDetails(data);
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _isLoadingVariantInfo = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingVariantInfo = false);
    }
  }

  void _extractSellerInfo(MobileVariantSelector data) {
    if (widget.item.brandName == null &&
        widget.item.sellerBusinessName == null &&
        widget.item.sellerUsername == null) {
      if (mounted) {
        setState(() {
          _fetchedBrandName = data.brandName;
          _fetchedSellerBusinessName = data.sellerBusinessName;
          _fetchedSellerUsername = data.sellerUsername;
        });
      }
    }
  }

  void _extractVariantDetails(MobileVariantSelector variantData) {
    final variantIdInt = int.tryParse(widget.item.variantId ?? '');
    if (variantIdInt == null) return;
    for (final colorOpt in variantData.colors) {
      for (final size in colorOpt.availableSizes) {
        if (size.variantId == variantIdInt) {
          if (mounted) {
            setState(() {
              _selectedColor = colorOpt.colorValue;
              _selectedColorDisplay = colorOpt.colorDisplay;
              _selectedSize = size.sizeValue;
            });
          }
          return;
        }
      }
    }
  }

  void _showVariantChangeSheet() {
    if (_variantData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Variant info loading, please wait...')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VariantChangeSheet(
        item: widget.item,
        variantData: _variantData!,
        currentColorDisplay: _selectedColorDisplay,
        currentSize: _selectedSize,
        onVariantSelected: (newVariantId, price, colorDisplay, sizeVal) async {
          Navigator.of(ctx).pop();
          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);
          final success = await cartProvider.changeItemVariant(
            itemId: widget.item.id,
            newVariantId: newVariantId,
            price: price,
          );
          if (mounted) {
            if (success) {
              setState(() {
                _selectedColorDisplay = colorDisplay;
                _selectedSize = sizeVal;
              });
              AppNotifications.showSuccess(context, 'Variant updated');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('❌ Failed to update variant'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ));
            }
          }
        },
      ),
    );
  }

  String? get _effectiveBrandName => widget.item.brandName?.isNotEmpty == true
      ? widget.item.brandName
      : _fetchedBrandName;

  String? get _effectiveSellerBusinessName =>
      widget.item.sellerBusinessName?.isNotEmpty == true
          ? widget.item.sellerBusinessName
          : _fetchedSellerBusinessName;

  String? get _effectiveSellerUsername =>
      widget.item.sellerUsername?.isNotEmpty == true
          ? widget.item.sellerUsername
          : _fetchedSellerUsername;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final isSelected = cartProvider.isSelected(widget.item.id);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          cartProvider.toggleItemSelection(widget.item.id),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10, top: 2),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.item.productInfo?.slug != null) {
                          context.push(
                              '/product/${widget.item.productInfo!.slug}');
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _isLoadingImage
                              ? const Center(
                                  child: SizedBox(
                                      width: 20,
                                      height: 30,
                                      child: LogoLoader()))
                              : _buildImageContent(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: widget.onRemove,
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          _buildSellerInfo(true),
                          const SizedBox(height: 6),
                          _buildVariantSection(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.item.isAvailable
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.item.isAvailable
                                    ? 'In Stock'
                                    : 'Out of Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.item.isAvailable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _qtyBtn(
                            icon: Icons.remove,
                            onPressed: widget.item.quantity > 1
                                ? widget.onDecrement
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              '${widget.item.quantity}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _qtyBtn(
                              icon: Icons.add, onPressed: widget.onIncrement),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.item.hasDiscount) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${(widget.item.regularPrice * widget.item.quantity).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade600,
                                  decorationThickness: 2,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(((widget.item.regularPrice - widget.item.salePrice) / widget.item.regularPrice) * 100).toInt()}% OFF',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              '₹${widget.item.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ] else ...[
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(bounds),
                            child: Text(
                              '₹${widget.item.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                        if (widget.item.quantity > 1) ...[
                          const SizedBox(height: 2),
                          Text(
                            '₹${widget.item.price.toStringAsFixed(0)} each',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSellerInfo(bool isCompact) {
    final brandName = _effectiveBrandName;
    final sellerBusinessName = _effectiveSellerBusinessName;
    final sellerUsername = _effectiveSellerUsername;

    if (_isLoadingVariantInfo &&
        brandName == null &&
        sellerBusinessName == null &&
        sellerUsername == null) {
      return Container(
        margin: EdgeInsets.only(top: isCompact ? 4 : 6),
        child: Row(children: [
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ]),
      );
    }
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
          if (sellerBusinessName != null && sellerBusinessName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 4 : 6),
              child: Row(children: [
                Icon(Icons.store_outlined,
                    size: isCompact ? 12 : 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sellerBusinessName,
                    style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            )
          else if (sellerUsername != null && sellerUsername.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isCompact ? 4 : 6),
              child: Row(children: [
                Icon(Icons.person_outline,
                    size: isCompact ? 12 : 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'by $sellerUsername',
                    style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = _variantImageUrl ?? widget.item.imageUrl;
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
      );
    }
    return Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400);
  }

  Widget _buildVariantSection() {
    final hasUsableData = _variantData != null &&
        _variantData!.colors.isNotEmpty &&
        _variantData!.colors.any((c) => c.availableSizes.isNotEmpty);

    if (_variantData != null &&
        _variantData!.colors.isNotEmpty &&
        widget.item.variantId == null) {
      return GestureDetector(
        onTap: hasUsableData
            ? _showVariantChangeSheet
            : () {
                if (widget.item.productInfo?.slug != null) {
                  context.push('/product/${widget.item.productInfo!.slug}');
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                hasUsableData ? 'Select variant' : 'View on product page',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                hasUsableData ? Icons.arrow_forward : Icons.open_in_new,
                size: 10,
                color: Colors.orange.shade900,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.item.variantId != null) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (_selectedColorDisplay != null)
            _chip(
              text: _selectedColorDisplay!,
              color: AppTheme.primaryColor,
              icon: _selectedColor != null
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        // ✅ FIX 1: was color.colorValue (undefined) → _selectedColor!
                        color: AppColorUtils.parse(_selectedColor!),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    )
                  : null,
            ),
          if (_selectedSize != null)
            _chip(text: _selectedSize!, color: AppTheme.secondaryColor),
          if (hasUsableData)
            GestureDetector(
              onTap: _showVariantChangeSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 9, color: Colors.grey.shade700),
                    const SizedBox(width: 2),
                    Text('Edit',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _chip({required String text, required Color color, Widget? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon, const SizedBox(width: 3)],
          Text(text,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  // ✅ FIX 2: _parseColor() REMOVED from this class

  Widget _qtyBtn({required IconData icon, required VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon,
            size: 16,
            color: onPressed != null
                ? AppTheme.primaryColor
                : Colors.grey.shade400),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VARIANT SELECTOR BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _VariantChangeSheet extends StatefulWidget {
  final CartItem item;
  final MobileVariantSelector variantData;
  final String? currentColorDisplay;
  final String? currentSize;
  final Function(
          String variantId, double price, String colorDisplay, String size)
      onVariantSelected;

  const _VariantChangeSheet({
    Key? key,
    required this.item,
    required this.variantData,
    required this.currentColorDisplay,
    required this.currentSize,
    required this.onVariantSelected,
  }) : super(key: key);

  @override
  State<_VariantChangeSheet> createState() => _VariantChangeSheetState();
}

class _VariantChangeSheetState extends State<_VariantChangeSheet> {
  int _colorIndex = 0;
  int? _sizeIndex;

  // ✅ FIX 3: _parseColor() REMOVED from this class too

  @override
  void initState() {
    super.initState();
    if (widget.currentColorDisplay != null) {
      final index = widget.variantData.colors
          .indexWhere((c) => c.colorDisplay == widget.currentColorDisplay);
      if (index >= 0) _colorIndex = index;
    }
    if (widget.currentSize != null &&
        _colorIndex < widget.variantData.colors.length) {
      final sizes = widget.variantData.colors[_colorIndex].availableSizes;
      final sizeIdx =
          sizes.indexWhere((s) => s.sizeValue == widget.currentSize);
      if (sizeIdx >= 0) _sizeIndex = sizeIdx;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.variantData.colors;
    final sizes = colors.isNotEmpty && _colorIndex < colors.length
        ? colors[_colorIndex].availableSizes
        : [];
    final selectedSizeOpt = sizes.isEmpty
        ? null
        : (_sizeIndex != null && _sizeIndex! >= 0 && _sizeIndex! < sizes.length)
            ? sizes[_sizeIndex!]
            : null;
    final canConfirm = sizes.isEmpty ? true : selectedSizeOpt != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Text(
                    widget.currentSize != null
                        ? 'Change Variant'
                        : 'Select Variant',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close,
                        color: Colors.grey.shade600, size: 24),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  widget.item.name,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    if (colors.isNotEmpty) ...[
                      Text(
                        'Color' +
                            (_colorIndex < colors.length
                                ? ': ${colors[_colorIndex].colorDisplay}'
                                : ''),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: colors.length,
                          itemBuilder: (context, i) {
                            // ✅ renamed colorOpt to avoid conflict with Color type
                            final colorOpt = colors[i];
                            final isSel = i == _colorIndex;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _colorIndex = i;
                                _sizeIndex = null;
                              }),
                              child: Container(
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? AppTheme.primaryColor
                                        : Colors.grey.shade300,
                                    width: isSel ? 3 : 2,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        // ✅ AppColorUtils replaces old _parseColor
                                        AppColorUtils.parse(
                                            colorOpt.colorValue),
                                        AppColorUtils.parse(colorOpt.colorValue)
                                            .withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (colors.isNotEmpty) ...[
                      Text(
                        'Size' +
                            (selectedSizeOpt != null
                                ? ': ${selectedSizeOpt.sizeDisplay}'
                                : ''),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (sizes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'One size only - no size selection needed',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(sizes.length, (i) {
                            final sizeOpt = sizes[i];
                            final isSel = i == _sizeIndex;
                            String displayText = sizeOpt.sizeDisplay;
                            if (displayText.toLowerCase() == 'small')
                              displayText = 'S';
                            else if (displayText.toLowerCase() == 'medium')
                              displayText = 'M';
                            else if (displayText.toLowerCase() == 'large')
                              displayText = 'L';
                            else if (displayText.toLowerCase() == 'extra large')
                              displayText = 'XL';
                            else if (displayText.toLowerCase() == '2x large')
                              displayText = '2XL';
                            return GestureDetector(
                              onTap: () => setState(() => _sizeIndex = i),
                              child: Container(
                                width: 45,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient:
                                      isSel ? AppTheme.primaryGradient : null,
                                  color: isSel ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.transparent
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(displayText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSel
                                            ? Colors.white
                                            : Colors.black87,
                                      )),
                                ),
                              ),
                            );
                          }),
                        ),
                      const SizedBox(height: 60),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: canConfirm
                            ? AppTheme.primaryGradient
                            : LinearGradient(colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade400
                              ]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canConfirm
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed: canConfirm
                            ? () {
                                final colorOpt = colors[_colorIndex];
                                if (sizes.isEmpty) {
                                  if (colorOpt.availableSizes.isEmpty) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          '⚠️ This product does not support variant changes'),
                                      backgroundColor: Colors.orange,
                                      duration: Duration(seconds: 2),
                                    ));
                                    return;
                                  }
                                  final firstVariant =
                                      colorOpt.availableSizes[0];
                                  widget.onVariantSelected(
                                    firstVariant.variantId.toString(),
                                    (firstVariant.price ?? widget.item.price)
                                        .toDouble(),
                                    colorOpt.colorDisplay,
                                    firstVariant.sizeValue,
                                  );
                                } else if (selectedSizeOpt != null) {
                                  widget.onVariantSelected(
                                    selectedSizeOpt.variantId.toString(),
                                    (selectedSizeOpt.price ?? widget.item.price)
                                        .toDouble(),
                                    colorOpt.colorDisplay,
                                    selectedSizeOpt.sizeValue,
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          canConfirm
                              ? (widget.currentSize != null
                                  ? 'Confirm Change'
                                  : 'Confirm Selection')
                              : 'Please select a size',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
