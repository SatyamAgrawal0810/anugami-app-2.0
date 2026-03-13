// lib/presentation/pages/categories/categories_page.dart

import 'dart:math' as math;
import 'package:anu_app/providers/optimized_product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/categories/category_tree_products_page.dart';
import 'package:anu_app/providers/product_provider.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/category_list_item.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with TickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();

  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  String? _error;

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
      duration: const Duration(seconds: 30),
    )..repeat();

    final icons = [
      Icons.shopping_bag_outlined,
      Icons.shopping_cart_outlined,
      Icons.local_offer_outlined,
      Icons.star_outline,
      Icons.favorite_outline,
      Icons.category_outlined,
    ];

    _floatingIcons = List.generate(14, (index) {
      return FloatingIcon(
        icon: icons[index % icons.length],
        color: AppTheme.primaryColor.withOpacity(0.6),
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 10 + 20,
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
      appBar: const CustomAppBar(
        title: 'Categories',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // 🌈 Soft gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.06),
                  Colors.white,
                  AppTheme.secondaryColor.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ Floating icons layer
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Stack(
                    children: _floatingIcons.map((icon) {
                      final progress =
                          (_floatingController.value + icon.delay) % 1.0;
                      final y =
                          icon.y + (progress * icon.speed * 2) - icon.speed;

                      return Positioned(
                        left: MediaQuery.of(context).size.width * icon.x,
                        top: MediaQuery.of(context).size.height * (y % 1.0),
                        child: Opacity(
                          opacity: 0.18, // 👈 visible but subtle
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
          'Error loading categories',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return CategoryListItem(
          category: _categories[index],
          onTap: _navigateToCategory,
        );
      },
    );
  }

  void _navigateToCategory(CategoryModel category) {
    final productProvider =
        Provider.of<OptimizedProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryTreeProductsPage(
          categorySlug: category.slug,
          title: category.name,
          initialBreadcrumbs: [category],
        ),
      ),
    );
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
