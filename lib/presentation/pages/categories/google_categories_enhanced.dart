// lib/presentation/pages/categories/image_categories_themed.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/config/theme.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';

class ImageCategoriesThemed extends StatefulWidget {
  const ImageCategoriesThemed({Key? key}) : super(key: key);

  @override
  State<ImageCategoriesThemed> createState() => _ImageCategoriesThemedState();
}

class _ImageCategoriesThemedState extends State<ImageCategoriesThemed>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _error;
  bool _isGridView = false; // Start with list view

  // 🔹 Floating background animation
  late AnimationController _floatingController;
  late AnimationController _cardsAnimController;
  late List<FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();
    _initFloatingBackground();
    _cardsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCategories();
  }

  void _initFloatingBackground() {
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    final icons = [
      Icons.shopping_bag_outlined,
      Icons.shopping_cart_outlined,
      Icons.local_offer_outlined,
      Icons.category_outlined,
      Icons.favorite_outline,
      Icons.star_outline,
    ];

    _floatingIcons = List.generate(12, (index) {
      return FloatingIcon(
        icon: icons[index % icons.length],
        color: AppTheme.primaryColor.withOpacity(0.6),
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 10 + 18,
        speed: math.Random().nextDouble() * 0.25 + 0.1,
        delay: math.Random().nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _cardsAnimController.dispose();
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
        _isLoading = false;
      });
      _cardsAnimController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Categories',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => context.push('/wishlist'),
            tooltip: 'Wishlist',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            onPressed: () => context.push('/cart'),
            tooltip: 'Cart',
          ),
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
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🌈 Soft gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.backgroundColor.withOpacity(0.06),
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ Floating icons animation
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
                        top: 100 + (screen.height * 0.55 * (y % 1.0)),
                        child: Opacity(
                          opacity: 0.15,
                          child: Transform.rotate(
                            angle: progress * 2 * math.pi,
                            child: Icon(
                              icon.icon,
                              size: icon.size,
                              color: icon.color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // 🧱 Foreground content
          RefreshIndicator(
            onRefresh: _loadCategories,
            color: AppTheme.primaryColor,
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LogoLoader());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('No categories available'),
      );
    }

    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildImageCategoryCard(_categories[index], index);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return _buildListCategoryCard(_categories[index], index);
      },
    );
  }

  Widget _buildImageCategoryCard(CategoryModel category, int index) {
    final delay = index * 60;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
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
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category name at top
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Category image - larger, takes remaining space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: category.imageUrl != null
                          ? Image.network(
                              category.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage(
                                    category.name, double.infinity);
                              },
                            )
                          : _buildPlaceholderImage(
                              category.name, double.infinity),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCategoryCard(CategoryModel category, int index) {
    final delay = index * 60;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToCategory(category),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Category image on the left
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: category.imageUrl != null
                          ? Image.network(
                              category.imageUrl!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage(
                                    category.name, 90);
                              },
                            )
                          : _buildPlaceholderImage(category.name, 90),
                    ),

                    const SizedBox(width: 20),

                    // Category name - single line
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1, // Single line only!
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String categoryName, double size) {
    // Generate gradient colors based on category
    final gradients = [
      [AppTheme.primaryColor, AppTheme.secondaryColor],
      [AppTheme.secondaryColor, AppTheme.accentColor],
      [const Color(0xFFFEAF4E), const Color(0xFFF96A4C)],
      [const Color(0xFFF96A4C), const Color(0xFFE54481)],
      [const Color(0xFFFFB380), const Color(0xFFFF8566)],
    ];

    final gradientIndex = categoryName.length % gradients.length;
    final gradient = gradients[gradientIndex];

    return Container(
      width: size == double.infinity ? double.infinity : size,
      height: size == double.infinity ? double.infinity : size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withOpacity(0.2),
            gradient[1].withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(categoryName),
          size: size == double.infinity ? 48 : size * 0.4,
          color: gradient[0].withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('men') && !name.contains('women')) {
      return Icons.checkroom;
    } else if (name.contains('women')) {
      return Icons.person;
    } else if (name.contains('kid') || name.contains('child')) {
      return Icons.child_care;
    } else if (name.contains('new season') || name.contains('trending')) {
      return Icons.auto_awesome;
    } else if (name.contains('footwear') || name.contains('shoe')) {
      return Icons.style;
    } else if (name.contains('home') || name.contains('lifestyle')) {
      return Icons.weekend;
    } else if (name.contains('jewel')) {
      return Icons.diamond;
    } else if (name.contains('accessor')) {
      return Icons.watch;
    } else if (name.contains('lingerie') || name.contains('intimate')) {
      return Icons.favorite;
    } else if (name.contains('beauty') || name.contains('cosmetic')) {
      return Icons.face_retouching_natural;
    } else if (name.contains('electronic') || name.contains('tech')) {
      return Icons.devices;
    } else if (name.contains('sport')) {
      return Icons.sports_soccer;
    } else if (name.contains('book')) {
      return Icons.menu_book;
    } else if (name.contains('toy')) {
      return Icons.toys;
    } else if (name.contains('pet')) {
      return Icons.pets;
    }

    return Icons.category;
  }

  void _navigateToCategory(CategoryModel category) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    // Check if category has subcategories
    if (category.children.isNotEmpty) {
      // Navigate to subcategory page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryDisplayPage(
            parentCategory: category,
          ),
        ),
      );
    } else {
      // Navigate directly to products page
      context
          .push('/category-products/${category.slug}?title=${category.name}');
    }
  }
}

// ================= SUBCATEGORY DISPLAY PAGE =================

class SubcategoryDisplayPage extends StatelessWidget {
  final CategoryModel parentCategory;

  const SubcategoryDisplayPage({
    Key? key,
    required this.parentCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: parentCategory.name,
        showBackButton: true,
      ),
      body: parentCategory.children.isEmpty
          ? const Center(child: Text('No subcategories found'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount:
                  parentCategory.children.length + 1, // +1 for "View All"
              itemBuilder: (context, index) {
                // First item is "View All"
                if (index == 0) {
                  return _buildViewAllCard(context);
                }

                // Rest are subcategories
                final subcategory = parentCategory.children[index - 1];
                return _buildSubcategoryListItem(
                    context, subcategory, index - 1);
              },
            ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  // 🌟 VIEW ALL CARD - Shows all products of parent category
  Widget _buildViewAllCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAllProducts(context),
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon with gradient background
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'View All Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'See all ${parentCategory.name} products',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 📋 SUBCATEGORY LIST ITEM
  Widget _buildSubcategoryListItem(
      BuildContext context, CategoryModel subcategory, int index) {
    final delay = index * 60;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToSubcategory(context, subcategory),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Subcategory Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: subcategory.imageUrl != null
                          ? Image.network(
                              subcategory.imageUrl!,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderIcon(subcategory.name);
                              },
                            )
                          : _buildPlaceholderIcon(subcategory.name),
                    ),

                    const SizedBox(width: 16),

                    // Subcategory Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subcategory.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subcategory.children.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${subcategory.children.length} subcategories',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Arrow Icon
                    Icon(
                      subcategory.children.isNotEmpty
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.shopping_bag_outlined,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(String categoryName) {
    final gradients = [
      [AppTheme.primaryColor, AppTheme.secondaryColor],
      [AppTheme.secondaryColor, AppTheme.accentColor],
      [const Color(0xFFFEAF4E), const Color(0xFFF96A4C)],
      [const Color(0xFFF96A4C), const Color(0xFFE54481)],
    ];

    final gradientIndex = categoryName.length % gradients.length;
    final gradient = gradients[gradientIndex];

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient[0].withOpacity(0.2),
            gradient[1].withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          Icons.category,
          size: 32,
          color: gradient[0].withOpacity(0.6),
        ),
      ),
    );
  }

  // 🌐 Navigate to ALL products of parent category
  void _navigateToAllProducts(BuildContext context) {
    print('🌐 Viewing ALL products of: ${parentCategory.name}');
    print('📦 Category slug: ${parentCategory.slug}');

    // Navigate to products page showing ALL products of this parent category
    context.push(
        '/category-products/${parentCategory.slug}?title=${parentCategory.name}');
  }

  // 📂 Navigate to subcategory (recursive)
  void _navigateToSubcategory(BuildContext context, CategoryModel subcategory) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);

    // Add subcategory to breadcrumbs
    productProvider.addCategoryToBreadcrumbs(subcategory);

    print('📂 Navigating to: ${subcategory.name}');
    print('👶 Children Count: ${subcategory.children.length}');

    // Check if this subcategory has children (nested subcategories)
    if (subcategory.children.isNotEmpty) {
      print('✅ Has nested subcategories, showing another subcategory page');
      // Navigate to another subcategory page (recursive)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryDisplayPage(
            parentCategory: subcategory,
          ),
        ),
      );
    } else {
      print('✅ No more subcategories, showing products page');
      // Navigate to products page (final destination)
      context.push(
          '/category-products/${subcategory.slug}?title=${subcategory.name}');
    }
  }
}

// ================= MODEL =================

class FloatingIcon {
  final IconData icon;
  final Color color;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

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
