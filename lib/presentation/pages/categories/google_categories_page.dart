// lib/presentation/pages/categories/google_categories_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:anu_app/config/theme.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../shared/custom_bottom_nav.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class GoogleCategoriesPage extends StatefulWidget {
  const GoogleCategoriesPage({Key? key}) : super(key: key);

  @override
  State<GoogleCategoriesPage> createState() => _GoogleCategoriesPageState();
}

class _GoogleCategoriesPageState extends State<GoogleCategoriesPage>
    with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  List<CategoryModel> _filteredCategories = [];
  String? _error;

  late AnimationController _animationController;

  // Brand colors based on your gradient theme
  final List<Color> _categoryColors = [
    const Color(0xFFFEAF4E), // Primary gradient start
    const Color(0xFFF96A4C), // Primary/Secondary
    const Color(0xFFE54481), // Accent
    const Color(0xFFFF8566), // Light coral
    const Color(0xFFFFB380), // Peach
    const Color(0xFFE86B92), // Pink coral
    const Color(0xFFFFA15C), // Warm orange
    const Color(0xFFFF6B9D), // Bright pink
    const Color(0xFFFFC76B), // Golden orange
    const Color(0xFFE57373), // Soft red
    const Color(0xFFFFAB91), // Light orange
    const Color(0xFFF48FB1), // Light pink
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _categoryService.getCategoryTree();
      setState(() {
        _categories = categories;
        _filteredCategories = categories;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((category) => category.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Color _getCategoryColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoading() : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Bar Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories',
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterCategories();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: LogoLoader());
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildError();
    }

    if (_filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppTheme.primaryColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(_filteredCategories[index], index);
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final color = _getCategoryColor(index);
    final delay = index * 50;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToCategory(category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Colored circle with icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: category.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            category.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                _getCategoryIcon(category.name),
                                size: 36,
                                color: color,
                              );
                            },
                          ),
                        )
                      : Icon(
                          _getCategoryIcon(category.name),
                          size: 36,
                          color: color,
                        ),
                ),
                const SizedBox(height: 16),
                // Category name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Product count (if available)
                if (category.productCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount} items',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorColor,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load categories',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _loadCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.15),
                  AppTheme.accentColor.withOpacity(0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: AppTheme.primaryColor,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('men') ||
        name.contains('clothing') ||
        name.contains('fashion')) {
      return Icons.checkroom_rounded;
    } else if (name.contains('electronic') || name.contains('tech')) {
      return Icons.devices_rounded;
    } else if (name.contains('food') || name.contains('grocery')) {
      return Icons.shopping_basket_rounded;
    } else if (name.contains('home') || name.contains('furniture')) {
      return Icons.home_rounded;
    } else if (name.contains('beauty') || name.contains('cosmetic')) {
      return Icons.face_rounded;
    } else if (name.contains('sport') || name.contains('fitness')) {
      return Icons.sports_soccer_rounded;
    } else if (name.contains('book')) {
      return Icons.menu_book_rounded;
    } else if (name.contains('toy') || name.contains('game')) {
      return Icons.toys_rounded;
    } else if (name.contains('baby') || name.contains('kid')) {
      return Icons.child_care_rounded;
    } else if (name.contains('jewelry') || name.contains('watch')) {
      return Icons.watch_rounded;
    } else if (name.contains('pet')) {
      return Icons.pets_rounded;
    } else if (name.contains('garden')) {
      return Icons.yard_rounded;
    }

    return Icons.category_rounded;
  }

  void _navigateToCategory(CategoryModel category) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    context.push('/category-products/${category.slug}?title=${category.name}');
  }
}
