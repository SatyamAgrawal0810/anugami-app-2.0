// lib/presentation/pages/product/category_tree_products_page.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/product/widgets/product_grid_item.dart';
import 'package:anu_app/presentation/pages/product/widgets/product_list_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/category_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../../widgets/breadcrumb_navigation.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

class CategoryTreeProductsPage extends StatefulWidget {
  final String title;
  final String categorySlug;
  final List<CategoryModel>? initialBreadcrumbs;

  const CategoryTreeProductsPage({
    Key? key,
    required this.title,
    required this.categorySlug,
    this.initialBreadcrumbs,
  }) : super(key: key);

  @override
  State<CategoryTreeProductsPage> createState() =>
      _CategoryTreeProductsPageState();
}

class _CategoryTreeProductsPageState extends State<CategoryTreeProductsPage> {
  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initCategoryData();
  }

  Future<void> _initCategoryData() async {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // Set initial breadcrumbs if provided
    if (widget.initialBreadcrumbs != null &&
        widget.initialBreadcrumbs!.isNotEmpty) {
      productProvider.setCategoryBreadcrumbs(widget.initialBreadcrumbs!);
    } else {
      // Load breadcrumbs for this category
      await productProvider.loadCategoryWithBreadcrumbs(widget.categorySlug);
    }

    // Load products
    await _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final productProvider =
          Provider.of<OptimizedProductProvider>(context, listen: false);
      await productProvider.loadProductsByCategoryTree(widget.categorySlug);

      // Check if we got an error but no products
      if (mounted &&
          productProvider.categoryTreeError != null &&
          productProvider.categoryTreeProducts.isEmpty) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.categoryTreeError!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Show error message for uncaught exceptions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    }
  }

  void _navigateToProductDetails(ProductModel product) {
    context.push('/product/${product.slug}');
  }

  void _navigateToSubcategory(CategoryModel subcategory) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // Add this subcategory to breadcrumbs
    productProvider.addCategoryToBreadcrumbs(subcategory);

    // Navigate to subcategory
    context
        .go('/category-products/${subcategory.slug}?title=${subcategory.name}');
  }

  void _onBreadcrumbTap(CategoryModel category, int index) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // Update breadcrumbs up to this point
    productProvider.setBreadcrumbsUpToIndex(index);

    // Navigate to the selected breadcrumb category
    context.pushReplacement(
        '/category-products/${category.slug}?title=${category.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
        actions: [
          // View toggle button
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Consumer<OptimizedProductProvider>(
        builder: (context, productProvider, child) {
          final products = productProvider.categoryTreeProducts;
          final subcategories = productProvider.categoryTreeSubcategories;
          final breadcrumbs = productProvider.categoryBreadcrumbs;
          final isLoading = productProvider.isLoadingCategoryTree;
          final errorMessage = productProvider.categoryTreeError;

          return Column(
            children: [
              // Breadcrumb navigation
              BreadcrumbNavigation(
                breadcrumbs: breadcrumbs,
                onBreadcrumbTap: _onBreadcrumbTap,
              ),

              // Main content
              Expanded(
                child: _buildMainContent(
                  products: products,
                  subcategories: subcategories,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  productProvider: productProvider,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 1, // Categories tab
      ),
    );
  }

  Widget _buildMainContent({
    required List<ProductModel> products,
    required List<CategoryModel> subcategories,
    required bool isLoading,
    required String? errorMessage,
    required OptimizedProductProvider productProvider,
  }) {
    // Show loading state
    if (isLoading && products.isEmpty) {
      return Center(
        child: const LogoLoader(),
      );
    }

    // Show error state
    if (errorMessage != null && products.isEmpty && subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load products',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _loadProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state if no products and no subcategories
    if (products.isEmpty && subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found in this category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try browsing other categories',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // Show product list/grid with subcategories
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryGradient.colors[0],
      child: Column(
        children: [
          // Subcategories section (always show in horizontal scroll)
          if (subcategories.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    'Subcategories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final subcategory = subcategories[index];
                      return _buildSubcategoryItem(subcategory);
                    },
                  ),
                ),
                const Divider(height: 24),
              ],
            ),

          // Products heading
          if (products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Products list/grid
          Expanded(
            child: _isGridView
                ? _buildProductGrid(products, productProvider)
                : _buildProductList(products, productProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryItem(CategoryModel subcategory) {
    return GestureDetector(
      onTap: () => _navigateToSubcategory(subcategory),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: subcategory.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        subcategory.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category,
                          color: AppTheme.primaryGradient.colors[0],
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: AppTheme.primaryGradient.colors[0],
                      size: 30,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              subcategory.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductModel> products, OptimizedProductProvider productProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductGridItem(
          product: products[index],
          onTap: () => _navigateToProductDetails(products[index]),
          onWishlistTap: () =>
              productProvider.toggleWishlist(products[index], context),
        );
      },
    );
  }

  Widget _buildProductList(
      List<ProductModel> products, OptimizedProductProvider productProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductListItem(
          product: products[index],
          onTap: () => _navigateToProductDetails(products[index]),
          onWishlistTap: () =>
              productProvider.toggleWishlist(products[index], context),
        );
      },
    );
  }
}
