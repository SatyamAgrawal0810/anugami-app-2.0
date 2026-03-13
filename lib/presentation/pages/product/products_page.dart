// lib/presentation/pages/product/products_page_with_filters.dart
// UPDATED VERSION WITH COMPLETE FILTER IMPLEMENTATION

import 'package:anu_app/config/routes.dart';
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/product_filter_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../../../utils/product_filter_utils.dart';
import '../shared/custom_app_bar.dart';
import 'widgets/product_grid_item.dart';
import 'widgets/product_list_item.dart';
import 'widgets/product_filter_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class ProductsPage extends StatefulWidget {
  final String title;
  final String type;
  final String? categorySlug;

  const ProductsPage({
    Key? key,
    required this.title,
    required this.type,
    this.categorySlug,
  }) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _isGridView = true;
  final ScrollController _scrollController = ScrollController();

  // Filter state
  ProductFilterModel _filters = ProductFilterModel();
  List<ProductModel> _filteredProducts = [];
  List<String> _availableBrands = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    if (widget.categorySlug != null) {
      await productProvider.loadProductsByCategory(widget.categorySlug!);
    } else {
      switch (widget.type) {
        case 'featured':
          await productProvider.loadFeaturedProducts();
          break;
        case 'new_arrivals':
          await productProvider.loadNewArrivals();
          break;
        case 'best_sellers':
          await productProvider.loadBestSellers();
          break;
        default:
          await productProvider.getProducts();
          break;
      }
    }

    // Update filtered products and brands after loading
    _updateFilteredProducts();
  }

  Future<void> _loadMoreProducts() async {
    if (widget.categorySlug != null) {
      final productProvider =
          Provider.of<OptimizedProductProvider>(context, listen: false);
      if (!productProvider.isLoadingCategory &&
          productProvider.hasMoreCategoryProducts) {
        await productProvider.loadMoreCategoryProducts(widget.categorySlug!);
        _updateFilteredProducts();
      }
    }
  }

  void _updateFilteredProducts() {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    List<ProductModel> products = _getProductsList(productProvider);

    setState(() {
      // Get unique brands from all products
      _availableBrands = ProductFilterUtils.getUniqueBrands(products);

      // Apply filters and sorting
      _filteredProducts = ProductFilterUtils.applyFiltersAndSort(
        products,
        _filters,
      );
    });
  }

  List<ProductModel> _getProductsList(
      OptimizedProductProvider productProvider) {
    if (widget.categorySlug != null) {
      return productProvider.categoryProducts;
    } else {
      switch (widget.type) {
        case 'featured':
          return productProvider.featuredProducts;
        case 'new_arrivals':
          return productProvider.newArrivals;
        case 'best_sellers':
          return productProvider.bestSellers;
        default:
          return productProvider.allProducts;
      }
    }
  }

  void _navigateToProductDetails(ProductModel product) {
    context.push('/product/${product.slug}');
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ProductFilterSheet(
          currentFilters: _filters,
          availableBrands: _availableBrands,
          onApplyFilters: (ProductFilterModel newFilters) {
            setState(() {
              _filters = newFilters;
              _updateFilteredProducts();
            });
          },
        );
      },
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: const Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ...SortOption.values.map((option) {
              return ListTile(
                leading: _getSortIcon(option),
                title: Text(option.displayName),
                selected: _filters.sortBy == option,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _filters.sortBy = option;
                    _updateFilteredProducts();
                  });
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Icon _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.priceHighToLow:
        return const Icon(Icons.trending_down);
      case SortOption.priceLowToHigh:
        return const Icon(Icons.trending_up);
      case SortOption.newestFirst:
        return const Icon(Icons.new_releases);
      case SortOption.popularity:
        return const Icon(Icons.star);
      case SortOption.rating:
        return const Icon(Icons.star_rate);
      case SortOption.discount:
        return const Icon(Icons.local_offer);
    }
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
          // Sort button
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.sort,
                  color: Colors.white,
                ),
                if (_filters.sortBy != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _showSortOptions(context);
            },
          ),
          // Filter button with badge
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
                if (_filters.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              _showFilterOptions(context);
            },
          ),
        ],
      ),
      body: Consumer<OptimizedProductProvider>(
        builder: (context, productProvider, child) {
          bool isLoading = false;
          String? errorMessage;

          if (widget.categorySlug != null) {
            isLoading = productProvider.isLoadingCategory;
            errorMessage = productProvider.categoryError;
          } else {
            switch (widget.type) {
              case 'featured':
                isLoading = productProvider.isLoadingFeatured;
                errorMessage = productProvider.featuredError;
                break;
              case 'new_arrivals':
                isLoading = productProvider.isLoadingNewArrivals;
                errorMessage = productProvider.newArrivalsError;
                break;
              case 'best_sellers':
                isLoading = productProvider.isLoadingBestSellers;
                errorMessage = productProvider.bestSellersError;
                break;
              default:
                isLoading = productProvider.isLoadingAllProducts;
                errorMessage = productProvider.allProductsError;
                break;
            }
          }

          // Show loading state
          if (isLoading && _filteredProducts.isEmpty) {
            return const Center(
              child: LogoLoader(),
            );
          }

          // Show error state
          if (errorMessage != null && _filteredProducts.isEmpty) {
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
                  InkWell(
                    onTap: _loadProducts,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Show empty state
          if (_filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (_filters.hasActiveFilters)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _filters.reset();
                          _updateFilteredProducts();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          // Show products with active filter count
          return Column(
            children: [
              if (_filters.hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing ${_filteredProducts.length} filtered products',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filters.reset();
                            _updateFilteredProducts();
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _isGridView
                    ? _buildProductGrid(_filteredProducts, productProvider)
                    : _buildProductList(_filteredProducts, productProvider),
              ),
              if (isLoading && _filteredProducts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: LogoLoader(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(
      List<ProductModel> products, OptimizedProductProvider productProvider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductListItem(
          product: products[index],
          onTap: () => _navigateToProductDetails(products[index]),
          onWishlistTap: () async {
            await productProvider.toggleWishlist(products[index], context);
          },
        );
      },
    );
  }
}
