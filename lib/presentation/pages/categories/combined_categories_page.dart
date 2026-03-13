// lib/presentation/pages/categories/combined_categories_page.dart

import 'dart:math' as math;
import 'package:anu_app/providers/optimized_product_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/categories/category_tree_products_page.dart';
import 'package:anu_app/providers/product_provider.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/animated_category_list.dart';
import 'widgets/category_grid_item.dart';

class CombinedCategoriesPage extends StatefulWidget {
  const CombinedCategoriesPage({Key? key}) : super(key: key);

  @override
  State<CombinedCategoriesPage> createState() => _CombinedCategoriesPageState();
}

class _CombinedCategoriesPageState extends State<CombinedCategoriesPage>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _error;
  bool _isGridView = true;

  // 🔹 Floating background
  late AnimationController _floatingController;
  late List<FloatingIcon> _floatingIcons;

  @override
  void initState() {
    super.initState();
    _initFloatingBackground();
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

          // ✨ Floating icons (VISIBLE ZONE)
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
                        // 👇 Icons only in middle zone (cards gaps)
                        top: 100 + (screen.height * 0.55 * (y % 1.0)),
                        child: Opacity(
                          opacity: 0.22, // 🔥 clearly visible
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

          // 🧱 Foreground content (UNCHANGED)
          RefreshIndicator(
            onRefresh: _loadCategories,
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: const LogoLoader(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Failed to load categories',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return _isGridView ? _buildGridView() : _buildListView();
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return CategoryGridItem(
          category: _categories[index],
          onTap: _navigateToCategory,
        );
      },
    );
  }

  Widget _buildListView() {
    return AnimatedCategoryList(
      categories: _categories,
      onCategoryTap: _navigateToCategory,
    );
  }

  void _navigateToCategory(CategoryModel category) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    context.push('/category-products/${category.slug}?title=${category.name}');
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
