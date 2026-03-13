// lib/presentation/pages/product/enhanced_product_details_content.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/product/widgets/trust_badges_widget.dart';
import 'package:anu_app/presentation/widgets/reviews/average_rating_widget.dart';
import 'package:anu_app/presentation/widgets/reviews/review_form.dart';
import 'package:anu_app/presentation/widgets/reviews/review_list.dart';
import 'package:anu_app/providers/optimized_product_provider.dart';
import 'package:anu_app/providers/review_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/breadcrumb_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/mobile_variant_model.dart';
import '../../../providers/cart_provider.dart';
import 'widgets/breadcrumb_widget.dart';
import 'widgets/product_image_slider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:anu_app/utils/color_utils.dart';

class EnhancedProductDetailsContent extends StatefulWidget {
  final ProductModel product;
  final MobileVariantSelector? variantData;
  final List<BreadcrumbModel> breadcrumbs;
  final VoidCallback onWishlistToggle;

  const EnhancedProductDetailsContent({
    super.key,
    required this.product,
    this.variantData,
    this.breadcrumbs = const [],
    required this.onWishlistToggle,
  });

  @override
  State<EnhancedProductDetailsContent> createState() =>
      _EnhancedProductDetailsContentState();
}

class _EnhancedProductDetailsContentState
    extends State<EnhancedProductDetailsContent>
    with SingleTickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  String? _selectedColor;
  String? _selectedSize;
  int? _selectedVariantId;
  double? _selectedPrice;
  List<ImageModel> _currentImages = [];

  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _selectedTabIndex = _tabController.index);
    });
    _initializeVariants();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSimilarProducts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeVariants() {
    if (widget.variantData != null && widget.variantData!.colors.isNotEmpty) {
      _selectedColor = widget.variantData!.colors.first.colorValue;
      _updateCurrentImages();
    } else {
      _currentImages = widget.product.images;
    }
  }

  String _sanitizeHtml(String html) {
    if (html.isEmpty) return html;
    String s = html;
    s = s.replaceAll(RegExp(r'list-style-type\s*:\s*[^;"]+[;"]'), '');
    s = s.replaceAll(RegExp(r'list-style\s*:\s*[^;"]+[;"]'), '');
    s = s.replaceAll(RegExp(r'font-variant\s*:\s*[^;"]+[;"]'), '');
    s = s.replaceAll(RegExp(r'text-decoration-style\s*:\s*[^;"]+[;"]'), '');
    s = s.replaceAll(RegExp(r'style\s*=\s*["\x27][\s;]*["\x27]'), '');
    return s;
  }

  Future<void> _loadSimilarProducts() async {
    if (!mounted) return;
    if (widget.product.category.isNotEmpty) {
      final p = Provider.of<OptimizedProductProvider>(context, listen: false);
      await p.loadProductsByCategory(widget.product.category);
    }
  }

  void _updateCurrentImages() {
    if (_selectedColor != null) {
      final colorImages = widget.product.getImagesForColor(_selectedColor);
      setState(() => _currentImages = colorImages);
    } else {
      setState(() => _currentImages = widget.product.images);
    }
  }

  String _getCurrentPrice() {
    if (_selectedPrice != null) return '₹${_selectedPrice!.toStringAsFixed(2)}';
    return widget.product.formattedSalePrice;
  }

  bool _isVariantReady() {
    if (widget.variantData == null || widget.variantData!.colors.isEmpty)
      return true;
    return _selectedColor != null &&
        _selectedSize != null &&
        _selectedVariantId != null;
  }

  void _showReviewForm(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ReviewForm(
        productSlug: widget.product.slug,
        onSuccess: () => context
            .read<ReviewProvider>()
            .getProductReviews(widget.product.slug),
      ),
    ));
  }

  void _addToCart(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final price = _selectedPrice ??
        double.tryParse(widget.product.salePrice) ??
        double.tryParse(widget.product.regularPrice) ??
        0.0;
    cartProvider.addItem(
      widget.product,
      quantity: 1,
      variantId: _selectedVariantId?.toString(),
      price: price,
    );
    AppNotifications.showSuccess(context, 'Added to cart!');
  }

  void _buyNow(BuildContext context) {
    final price = _selectedPrice ??
        double.tryParse(widget.product.salePrice) ??
        double.tryParse(widget.product.regularPrice) ??
        0.0;
    final regularPrice = double.tryParse(widget.product.regularPrice) ?? 0.0;
    final params = {
      'buyNow': 'true',
      'productId': widget.product.id.toString(),
      'productName': Uri.encodeComponent(widget.product.name),
      'price': price.toString(),
      'regularPrice': regularPrice.toString(),
      'image': Uri.encodeComponent(widget.product.primaryImageUrl),
    };
    if (_selectedVariantId != null)
      params['variantId'] = _selectedVariantId.toString();
    if (_selectedColor != null)
      params['color'] = Uri.encodeComponent(_selectedColor!);
    if (_selectedSize != null)
      params['size'] = Uri.encodeComponent(_selectedSize!);
    context.push(
        '/checkout?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}');
  }

  void _showBrandDescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      const Icon(Icons.verified, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.product.brand.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                widget.product.brand.description.isNotEmpty
                    ? widget.product.brand.description
                    : 'This is an official verified brand on our platform.',
                style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: widget.product.brand.description.isNotEmpty
                        ? Colors.black87
                        : Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/brands/${widget.product.brand.slug}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('View Brand Products',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeChart() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.straighten,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Size Chart',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      _tc('Size', h: true),
                      _tc('Chest (in)', h: true),
                      _tc('Length (in)', h: true),
                    ],
                  ),
                  TableRow(children: [_tc('S'), _tc('36-38'), _tc('27')]),
                  TableRow(children: [_tc('M'), _tc('38-40'), _tc('28')]),
                  TableRow(children: [_tc('L'), _tc('40-42'), _tc('29')]),
                  TableRow(children: [_tc('XL'), _tc('42-44'), _tc('30')]),
                  TableRow(children: [_tc('2XL'), _tc('44-46'), _tc('31')]),
                ],
              ),
              const SizedBox(height: 16),
              Text('Note: Measurements are approximate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tc(String text, {bool h = false}) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: h ? 13 : 12,
                fontWeight: h ? FontWeight.bold : FontWeight.normal,
                color: h ? AppTheme.primaryColor : Colors.black87)),
      );

  // ── price section ────────────────────────────────────────────────────────────
  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
          child: Text(_getCurrentPrice(),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
        const SizedBox(width: 8),
        if (widget.product.discountPercentage.isNotEmpty) ...[
          Text(widget.product.formattedRegularPrice,
              style: TextStyle(
                  fontSize: 18,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFFF4947),
                borderRadius: BorderRadius.circular(4)),
            child: Text(widget.product.discountPercentage,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }

  Widget _buildStockInfo() {
    int stock = widget.product.stockQuantity;
    if (_selectedColor != null &&
        _selectedSize != null &&
        widget.variantData != null) {
      try {
        final co = widget.variantData!.colors
            .firstWhere((c) => c.colorValue == _selectedColor);
        final so =
            co.availableSizes.firstWhere((s) => s.sizeValue == _selectedSize);
        stock = so.stock;
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: stock > 0 ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(stock > 0 ? Icons.check_circle : Icons.error,
            size: 18, color: stock > 0 ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(
          stock > 0
              ? stock <= 5
                  ? 'Only $stock left in stock'
                  : 'In Stock'
              : 'Out of Stock',
          style: TextStyle(
              color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }

  Widget _buildEnhancedVariationSelector() {
    if (widget.variantData == null || widget.variantData!.colors.isEmpty)
      return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(width: 8),
          const Text('Select Variation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        _buildCompactColorSelector(),
        if (_selectedColor != null) ...[
          const SizedBox(height: 16),
          _buildCompactSizeSelector(),
        ],
      ]),
    );
  }

  Widget _buildCompactColorSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Color' +
            (_selectedColor != null
                ? ': ${widget.variantData!.colors.firstWhere((c) => c.colorValue == _selectedColor).colorDisplay}'
                : ''),
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.variantData!.colors.length,
          itemBuilder: (context, index) {
            final color = widget.variantData!.colors[index];
            final isSelected = _selectedColor == color.colorValue;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedColor = color.colorValue;
                _selectedSize = null;
                _selectedVariantId = null;
                _selectedPrice = null;
                _updateCurrentImages();
              }),
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
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
                        AppColorUtils.parse(color.colorValue),
                        AppColorUtils.parse(color.colorValue).withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildCompactSizeSelector() {
    final co = widget.variantData!.colors
        .firstWhere((c) => c.colorValue == _selectedColor);
    if (co.availableSizes.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(
          'Size' +
              (_selectedSize != null
                  ? ': ${co.availableSizes.firstWhere((s) => s.sizeValue == _selectedSize).sizeDisplay}'
                  : ''),
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showSizeChart,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.straighten, size: 12, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text('Size Chart',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: co.availableSizes.map((size) {
          final isSelected = _selectedSize == size.sizeValue;
          final isOOS = !size.inStock;
          String label = size.sizeDisplay;
          if (label.toLowerCase() == 'small') label = 'S';
          if (label.toLowerCase() == 'medium') label = 'M';
          if (label.toLowerCase() == 'large') label = 'L';
          if (label.toLowerCase() == 'extra large') label = 'XL';
          if (label.toLowerCase() == '2x large') label = '2XL';
          return GestureDetector(
            onTap: isOOS
                ? null
                : () => setState(() {
                      _selectedSize = size.sizeValue;
                      _selectedVariantId = size.variantId;
                      _selectedPrice = size.price;
                    }),
            child: Container(
              width: 45,
              height: 38,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected
                    ? null
                    : isOOS
                        ? Colors.grey.shade100
                        : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : isOOS
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
                    width: 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isOOS
                                ? Colors.grey.shade400
                                : Colors.black87)),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildEnhancedBrandSection() {
    final brand = widget.product.brand;
    if (brand.name.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 42,
              height: 42,
              color: Colors.grey.shade100,
              child: brand.logo.isNotEmpty
                  ? Image.network(brand.logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.store, color: Colors.grey.shade400))
                  : Icon(Icons.store, color: AppTheme.primaryColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(brand.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                if (brand.isVerified)
                  InkWell(
                    onTap: _showBrandDescriptionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.verified,
                            size: 12, color: Color(0xFF4CAF50)),
                        SizedBox(width: 4),
                        Text('Official',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50))),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => context.push('/brands/${brand.slug}'),
                child: Text('View all products ›',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor)),
              ),
            ]),
          ),
        ]),
        if (widget.product.sellerInfo != null) ...[
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(children: [
            Text('Sold by ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Expanded(
              child: Text(widget.product.sellerInfo!.userName,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.verified, size: 10, color: Color(0xFF4CAF50)),
                SizedBox(width: 4),
                Text('Verified',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50))),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
          ]),
        ],
      ]),
    );
  }

  // ── Tab section ──────────────────────────────────────────────────────────────
  Widget _buildProductDetailsTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(children: [
            const SizedBox(width: 8),
            const Text(
              'Product Details',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ]),
        ),

        // Tab row + animated gradient line
        Column(children: [
          Row(children: [
            _buildTabBtn(0, Icons.description_outlined, 'Description'),
            _buildTabBtn(1, Icons.settings_outlined, 'Specifications'),
            _buildTabBtn(2, Icons.local_shipping_outlined, 'Shipping'),
          ]),
          _AnugamiSweepLine(
            selectedIndex: _selectedTabIndex,
            tabCount: 3,
          ),
        ]),

        // Tab content
        Container(
          padding: const EdgeInsets.all(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildTabContent(),
          ),
        ),
      ]),
    );
  }

  Widget _buildTabBtn(int index, IconData icon, String label) {
    final sel = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _tabController.animateTo(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: sel ? Colors.black87 : Colors.black54),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                color: sel ? Colors.black87 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDescriptionTab();
      case 1:
        return _buildSpecificationsTab();
      case 2:
        return _buildShippingTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDescriptionTab() {
    final desc = widget.product.description.trim();
    if (desc.isEmpty)
      return const Text('No description available for this product.',
          style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey,
              fontStyle: FontStyle.italic));

    final plain = desc
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!_isDescriptionExpanded)
        Text(plain,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14, height: 1.6, color: Colors.black87)),
      if (_isDescriptionExpanded)
        Builder(builder: (ctx) {
          try {
            return Html(
              data: _sanitizeHtml(desc),
              style: {
                "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.6),
                    color: Colors.black87),
                "ul": Style(
                    margin: Margins.only(left: 16, top: 8, bottom: 8),
                    padding: HtmlPaddings.zero),
                "ol": Style(
                    margin: Margins.only(left: 16, top: 8, bottom: 8),
                    padding: HtmlPaddings.zero),
                "li": Style(
                    margin: Margins.only(bottom: 4),
                    padding: HtmlPaddings.zero),
              },
              onLinkTap: (url, _, __) async {
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            );
          } catch (_) {
            return Text(plain,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.black87));
          }
        }),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () =>
            setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
        child: Text(
          _isDescriptionExpanded ? 'Show Less ▲' : 'Show More ▼',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    ]);
  }

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSpecSection('Product Information', Icons.info_outline,
            const Color(0xFF4CAF50), _buildBasicSpecs()),
        const SizedBox(height: 20),
        if (widget.product.attributes.any((a) => a.isVisible))
          _buildSpecSection('Technical Specifications', Icons.settings_outlined,
              const Color(0xFF2196F3), _buildAttributeSpecs()),
        const SizedBox(height: 20),
        if (widget.variantData != null && widget.variantData!.colors.isNotEmpty)
          _buildSpecSection('Available Options', Icons.palette_outlined,
              const Color(0xFFFF9800), _buildVariantSpecs()),
      ]),
    );
  }

  Widget _buildSpecSection(String title, IconData icon, Color color,
      List<Map<String, String>> specs) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ]),
        ),
        ...specs.asMap().entries.map((entry) {
          final isLast = entry.key == specs.length - 1;
          final spec = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                            color: color.withOpacity(0.1), width: 1))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 2,
                  child: Text(spec['label']!,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700))),
              const SizedBox(width: 12),
              Expanded(
                  flex: 3,
                  child: Text(spec['value']!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87))),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  List<Map<String, String>> _buildBasicSpecs() {
    final specs = <Map<String, String>>[];
    if (_selectedColor != null && widget.variantData != null) {
      final co = widget.variantData!.colors
          .firstWhere((c) => c.colorValue == _selectedColor);
      specs.add({'label': 'Color', 'value': co.colorDisplay});
    }
    if (_selectedSize != null && widget.variantData != null) {
      final co = widget.variantData!.colors
          .firstWhere((c) => c.colorValue == _selectedColor);
      final so =
          co.availableSizes.firstWhere((s) => s.sizeValue == _selectedSize);
      specs.add({'label': 'Size', 'value': so.sizeDisplay});
    }
    try {
      final wa = widget.product.attributes.firstWhere((a) =>
          a.displayValue.toLowerCase().contains('weight') ||
          a.name.toLowerCase().contains('weight'));
      if (wa.value.isNotEmpty)
        specs.add({'label': 'Weight', 'value': wa.value});
    } catch (_) {}
    specs.add({
      'label': 'Stock Status',
      'value': widget.product.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
    });
    return specs;
  }

  List<Map<String, String>> _buildAttributeSpecs() {
    return widget.product.attributes
        .where((a) =>
            a.isVisible &&
            !a.displayValue.toLowerCase().contains('weight') &&
            !a.displayValue.toLowerCase().contains('size') &&
            !a.displayValue.toLowerCase().contains('color') &&
            !a.displayValue.toLowerCase().contains('colour') &&
            !a.name.toLowerCase().contains('size') &&
            !a.name.toLowerCase().contains('color') &&
            !a.name.toLowerCase().contains('colour'))
        .map((a) => {'label': a.displayValue, 'value': a.value})
        .toList();
  }

  List<Map<String, String>> _buildVariantSpecs() {
    if (widget.variantData == null || widget.variantData!.colors.isEmpty)
      return [];
    final colorNames = widget.variantData!.colors
        .map((c) => c.colorDisplay)
        .take(5)
        .join(', ');
    final more = widget.variantData!.colors.length > 7
        ? ' +${widget.variantData!.colors.length - 7} more'
        : '';
    final specs = [
      {'label': 'Available Colors', 'value': colorNames + more}
    ];
    final co = widget.variantData!.colors.firstWhere((c) =>
        c.colorValue ==
        (_selectedColor ?? widget.variantData!.colors.first.colorValue));
    if (co.availableSizes.isNotEmpty) {
      final sizes = co.availableSizes.map((s) {
        final d = s.sizeDisplay.toLowerCase();
        if (d == 'small') return 'S';
        if (d == 'medium') return 'M';
        if (d == 'large') return 'L';
        if (d == 'extra large') return 'XL';
        if (d == '2x large') return '2XL';
        return s.sizeDisplay;
      }).join(', ');
      specs.add({'label': 'Available Sizes', 'value': sizes});
    }
    int total = 0;
    for (var c in widget.variantData!.colors) total += c.availableSizes.length;
    specs.add({'label': 'Total Variants', 'value': '$total options'});
    return specs;
  }

  Widget _buildShippingTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _shipRow(Icons.local_shipping_outlined, 'Free Shipping',
          'On orders above ₹999', Colors.green),
      const SizedBox(height: 12),
      _shipRow(Icons.schedule_outlined, 'Delivery Time',
          'Estimated 3-5 business days', Colors.blue),
      const SizedBox(height: 12),
      _shipRow(Icons.keyboard_return_outlined, '7-Day Returns',
          'Easy returns & refunds', Colors.orange),
      const SizedBox(height: 12),
      _shipRow(Icons.verified_user_outlined, 'Secure Packaging',
          'Safe & secure delivery', const Color(0xFFD03FC0)),
    ]);
  }

  Widget _shipRow(IconData icon, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSimilarProductsSection() {
    return Consumer<OptimizedProductProvider>(
      builder: (context, pp, _) {
        final similar = pp.categoryProducts
            .where((p) => p.id != widget.product.id)
            .take(10)
            .toList();
        if (similar.isEmpty && !pp.isLoadingCategory)
          return const SizedBox.shrink();

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('You May Like This',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (similar.length > 4)
                    TextButton(
                      onPressed: () {
                        final cat = widget.breadcrumbs.isNotEmpty
                            ? widget.breadcrumbs.last.name
                            : 'Products';
                        context.push(
                            '/products?type=category&title=$cat&category=${widget.product.category}');
                      },
                      child: Text('View All',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600)),
                    ),
                ]),
          ),
          const SizedBox(height: 16),
          if (pp.isLoadingCategory)
            Container(
                height: 280,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: const Center(child: LogoLoader()))
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: similar.length,
                itemBuilder: (context, i) {
                  final p = similar[i];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => context.push('/product/${p.slug}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12)),
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: p.primaryImageUrl.isNotEmpty
                                        ? Image.network(p.primaryImageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Icon(
                                                Icons.image,
                                                color: Colors.grey[400],
                                                size: 40))
                                        : Icon(Icons.image,
                                            color: Colors.grey[400], size: 40),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                height: 1.2),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const Spacer(),
                                        ShaderMask(
                                          shaderCallback: (b) => AppTheme
                                              .primaryGradient
                                              .createShader(b),
                                          child: Text(p.formattedSalePrice,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                        ),
                                      ]),
                                ),
                              ),
                            ]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ]);
      },
    );
  }

  Widget _disabledBtn(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.breadcrumbs.isNotEmpty)
              BreadcrumbWidget(
                breadcrumbs: widget.breadcrumbs,
                onTap: (slug) {
                  if (slug.isEmpty) {
                    context.push('/home');
                  } else {
                    final name = widget.breadcrumbs
                        .firstWhere((b) => b.slug == slug,
                            orElse: () => BreadcrumbModel(
                                id: '', name: 'Category', slug: slug))
                        .name;
                    context.push(
                        '/products?type=category&title=$name&category=$slug');
                  }
                },
              ),
            ProductImageSlider(
              key: ValueKey(_currentImages.hashCode),
              images: _currentImages,
              videos: widget.product.videos,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(widget.product.name,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ),
                          Consumer<WishlistProvider>(
                            builder: (ctx2, wp, _) {
                              final wl =
                                  wp.isInWishlist(widget.product.id.toString());
                              return IconButton(
                                icon: Icon(
                                    wl ? Icons.favorite : Icons.favorite_border,
                                    color: wl
                                        ? const Color(0xFFFF4947)
                                        : Colors.grey),
                                onPressed: () async {
                                  await Provider.of<OptimizedProductProvider>(
                                          ctx2,
                                          listen: false)
                                      .toggleWishlist(widget.product, ctx2);
                                },
                              );
                            },
                          ),
                        ]),
                    const SizedBox(height: 8),
                    if (widget.product.brand.name.isNotEmpty)
                      Row(children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text('Brand: ${widget.product.brand.name}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                      ]),
                    const SizedBox(height: 16),
                    _buildPriceSection(),
                    const SizedBox(height: 16),
                    _buildStockInfo(),
                    const SizedBox(height: 20),
                    _buildEnhancedVariationSelector(),
                    _buildProductDetailsTabs(),
                    const SizedBox(height: 20),
                    _buildEnhancedBrandSection(),
                    const SizedBox(height: 20),
                    const TrustBadgesWidget(),
                    const SizedBox(height: 20),
                    Row(children: [
                      const SizedBox(width: 8),
                      const Text('Reviews & Ratings',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewForm(context),
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Write a Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                              color: AppTheme.primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ReviewList(productSlug: widget.product.slug),
                    const SizedBox(height: 20),
                    AverageRatingWidget(productSlug: widget.product.slug),
                    const SizedBox(height: 20),
                  ]),
            ),
            _buildSimilarProductsSection(),
            const SizedBox(height: 100),
          ]),
        ),
      ),

      // ── BOTTOM ACTION BAR ─────────────────────────────────────────────────────
      Consumer2<CartProvider, WishlistProvider>(
        builder: (ctx, cartProvider, wishlistProvider, _) {
          final productIdStr = widget.product.id.toString();
          final variantStr = _selectedVariantId?.toString();
          final ready = _isVariantReady();

          final isInCart = cartProvider.items.any((item) {
            final idMatch = (item.productInfo?.id ?? '') == productIdStr;
            final varMatch = (variantStr == null && item.variantId == null) ||
                (variantStr != null && item.variantId == variantStr);
            return idMatch && varMatch;
          });

          final isWishlisted = wishlistProvider.isInWishlist(productIdStr);

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3))
              ],
            ),
            child: SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (widget.variantData != null && !ready)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select '
                          '${_selectedColor == null ? 'color' : ''}'
                          '${_selectedColor == null && _selectedSize == null ? ' and ' : ''}'
                          '${_selectedSize == null ? 'size' : ''}'
                          ' to continue',
                          style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                Row(children: [
                  // LEFT: Wishlist
                  Expanded(
                    child: !ready
                        ? _disabledBtn(Icons.favorite_border, 'Wishlist')
                        : isWishlisted
                            ? InkWell(
                                onTap: () => context.push('/wishlist'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFFFF4947)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.favorite,
                                          color: Color(0xFFFF4947), size: 20),
                                      SizedBox(width: 8),
                                      Text('Go to Wishlist',
                                          style: TextStyle(
                                              color: Color(0xFFFF4947),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () async {
                                  await Provider.of<OptimizedProductProvider>(
                                          ctx,
                                          listen: false)
                                      .toggleWishlist(widget.product, ctx);
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppTheme.primaryColor),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.favorite_border,
                                          color: AppTheme.primaryColor,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text('Wishlist',
                                          style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                  ),

                  const SizedBox(width: 12),

                  // RIGHT: Add to Cart
                  Expanded(
                    child: !ready
                        ? _disabledBtn(
                            Icons.shopping_cart_outlined, 'Add to Cart')
                        : isInCart
                            ? InkWell(
                                onTap: () => context.push('/cart'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppTheme.primaryColor),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart,
                                          color: AppTheme.primaryColor,
                                          size: 20),
                                      SizedBox(width: 8),
                                      Text('Go to Cart',
                                          style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              )
                            : InkWell(
                                onTap: () => _addToCart(ctx),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Add to Cart',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnugamiSweepLine — animated gradient indicator below tabs
// ─────────────────────────────────────────────────────────────────────────────
class _AnugamiSweepLine extends StatefulWidget {
  final int selectedIndex;
  final int tabCount;

  const _AnugamiSweepLine({
    required this.selectedIndex,
    required this.tabCount,
  });

  @override
  State<_AnugamiSweepLine> createState() => _AnugamiSweepLineState();
}

class _AnugamiSweepLineState extends State<_AnugamiSweepLine>
    with TickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<double> _slideAnim;
  double _prevPosition = 0;
  double _targetPosition = 0;

  late AnimationController _sweepCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut);
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _targetPosition = widget.selectedIndex / widget.tabCount;
    _prevPosition = _targetPosition;
  }

  @override
  void didUpdateWidget(_AnugamiSweepLine old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) {
      _prevPosition = old.selectedIndex / widget.tabCount;
      _targetPosition = widget.selectedIndex / widget.tabCount;
      _slideCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _sweepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segmentWidth = 1.0 / widget.tabCount;

    return SizedBox(
      height: 2,
      child: LayoutBuilder(builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final lineWidth = totalWidth * segmentWidth;

        return AnimatedBuilder(
          animation: Listenable.merge([_slideAnim, _sweepCtrl]),
          builder: (context, _) {
            final left = totalWidth *
                (_prevPosition +
                    (_targetPosition - _prevPosition) * _slideAnim.value);

            final sweepOffset =
                -lineWidth + (_sweepCtrl.value * (totalWidth + lineWidth * 2));

            return Stack(children: [
              // faint base track
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFBB4E).withOpacity(0.22),
                        const Color(0xFFF74A4C).withOpacity(0.22),
                        const Color(0xFF7E22CE).withOpacity(0.22),
                      ],
                    ),
                  ),
                ),
              ),

              // active segment
              Positioned(
                left: left,
                width: lineWidth,
                top: 0,
                bottom: 0,
                child: ClipRect(
                  child: Stack(children: [
                    // gradient base
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFBB4E),
                            Color(0xFFF74A4C),
                            Color(0xFF7E22CE),
                          ],
                        ),
                      ),
                    ),
                    // shimmer sweep
                    Positioned(
                      left: sweepOffset - left,
                      width: lineWidth * 0.6,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFBB4E).withOpacity(0.9),
                              const Color(0xFFF74A4C).withOpacity(0.9),
                              const Color(0xFF7E22CE).withOpacity(0.9),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.3, 0.5, 0.7, 1],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]);
          },
        );
      }),
    );
  }
}
