// lib/presentation/pages/search/search_page.dart
// ✨ WITH ROTATING SEARCH SUGGESTIONS

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../../../config/theme.dart';
import '../home/widgets/product_card.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isGridView = true;
  List<String> _recentSearches = [];

  // ✅ ENABLE REAL-TIME SEARCH
  bool _enableRealtimeSearch = true;

  // 🔄 Animation controllers for rotating suggestions
  late AnimationController _suggestionAnimationController;
  late Animation<double> _suggestionFadeAnimation;
  late Animation<Offset> _suggestionSlideAnimation;
  int _currentSuggestionIndex = 0;

  // 🔄 Rotating search suggestions in search field
  final List<String> _rotatingSearchSuggestions = [
    'Search "Mascara"',
    'Search "Night Cream"',
    'Search "Kurtis"',
    'Search "T-shirts"',
    'Search "Wallets"',
    'Search "Joggers"',
    'Search "Dresses"',
  ];

  List<String> _searchSuggestions = [
    'Smartphones',
    'Laptops',
    'Headphones',
    'Gaming',
    'Accessories',
    'Electronics',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize suggestion animation controller
    _suggestionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _suggestionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _suggestionAnimationController,
      curve: Curves.easeInOut,
    ));

    _suggestionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _suggestionAnimationController,
      curve: Curves.easeOut,
    ));

    // Start suggestion rotation
    _suggestionAnimationController.forward();
    _startSuggestionRotation();

    // ✅ Add listener for real-time search
    if (_enableRealtimeSearch) {
      _searchController.addListener(_onSearchTextChanged);
      print('✅ Real-time search ENABLED');
    }

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }

    // Auto-focus the search field when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _startSuggestionRotation() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _searchController.text.isEmpty) {
        _suggestionAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentSuggestionIndex = (_currentSuggestionIndex + 1) %
                  _rotatingSearchSuggestions.length;
            });
            _suggestionAnimationController.forward();
            _startSuggestionRotation();
          }
        });
      } else {
        // If user is typing, restart rotation check
        _startSuggestionRotation();
      }
    });
  }

  @override
  void dispose() {
    // ✅ Remove listener
    if (_enableRealtimeSearch) {
      _searchController.removeListener(_onSearchTextChanged);
    }
    _suggestionAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ✅ REAL-TIME SEARCH: Called automatically when text changes
  void _onSearchTextChanged() {
    final query = _searchController.text.trim();

    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // If query is empty, clear results
    if (query.isEmpty) {
      productProvider.clearSearch();
      return;
    }

    // Search when query is at least 2 characters
    if (query.length >= 2) {
      print('📝 Real-time search triggered: "$query"');
      productProvider.searchProductsDebounced(query);
    } else {
      print('⏸️ Query too short: "$query" (need at least 2 characters)');
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // Use immediate search when user presses enter
    print('🔍 Manual search (Enter pressed): "$query"');
    productProvider.searchProducts(query.trim());

    // Add to recent searches
    setState(() {
      _recentSearches.remove(query.trim());
      _recentSearches.insert(0, query.trim());
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });

    // Unfocus keyboard
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();

    // Clear results
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    productProvider.clearSearch();
  }

  void _navigateToProductDetails(ProductModel product) {
    context.push('/product/${product.slug}');
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          // 🔄 Animated rotating hint text
          hintText: _searchController.text.isEmpty
              ? _rotatingSearchSuggestions[_currentSuggestionIndex]
              : 'Search products...',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
          prefixIcon: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
        onChanged: (value) {
          setState(() {}); // Rebuild to show/hide clear button
        },
      ),
    );
  }

  // ✅ Shows loading spinner while searching or clear button
  Widget _buildSuffixIcon() {
    return Consumer<OptimizedProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSearch) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          );
        }

        if (_searchController.text.isNotEmpty) {
          return IconButton(
            icon: Icon(
              Icons.clear,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: _clearSearch,
          );
        }

        // Voice search icon (optional)
        return IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) =>
                AppTheme.primaryGradient.createShader(bounds),
            child: const Icon(
              Icons.mic_none_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () {
            // TODO: Implement voice search
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice search coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            search,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Searches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchSuggestions.map((suggestion) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _searchController.text = suggestion;
                      _performSearch(suggestion);
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or browse our categories',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => context.push('/categories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Browse Categories'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    if (_isGridView) {
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => _navigateToProductDetails(product),
            onWishlistTap: (product) async {
              final productProvider =
                  Provider.of<OptimizedProductProvider>(context, listen: false);
              await productProvider.toggleWishlist(product, context);
            },
          );
        },
      );
    } else {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: ProductCard(
              product: product,
              onTap: () => _navigateToProductDetails(product),
              onWishlistTap: (product) async {
                final productProvider = Provider.of<OptimizedProductProvider>(
                    context,
                    listen: false);
                await productProvider.toggleWishlist(product, context);
              },
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search',
        showBackButton: true,
        actions: [
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
      body: Column(
        children: [
          // 🔄 Search field with rotating suggestions
          AnimatedBuilder(
            animation: _suggestionAnimationController,
            builder: (context, child) {
              return _buildSearchField();
            },
          ),
          Expanded(
            child: Consumer<OptimizedProductProvider>(
              builder: (context, productProvider, child) {
                final searchResults = productProvider.searchResults;
                final isLoading = productProvider.isLoadingSearch;
                final errorMessage = productProvider.searchError;

                if (isLoading) {
                  return const Center(
                    child: LogoLoader(),
                  );
                }

                if (errorMessage != null) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (_searchController.text.isNotEmpty) {
                                  _performSearch(_searchController.text);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (searchResults.isEmpty) {
                  if (_searchController.text.isEmpty) {
                    // Show initial state with recent searches and suggestions
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildRecentSearches(),
                          const SizedBox(height: 24),
                          _buildSearchSuggestions(),
                        ],
                      ),
                    );
                  } else {
                    // Show empty search results
                    return _buildEmptyState();
                  }
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Results header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${searchResults.length} results for "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Products grid/list
                      _buildProductGrid(searchResults),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(
        currentIndex: 0,
      ),
    );
  }
}
