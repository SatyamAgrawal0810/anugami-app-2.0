// lib/presentation/pages/categories/category_grid_page.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/categories/category_tree_products_page.dart';
import 'package:anu_app/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/services/category_service.dart';
import '../../../core/models/category_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/category_grid_item.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class CategoryGridPage extends StatefulWidget {
  const CategoryGridPage({Key? key}) : super(key: key);

  @override
  State<CategoryGridPage> createState() => _CategoryGridPageState();
}

class _CategoryGridPageState extends State<CategoryGridPage> {
  final CategoryService _categoryService = CategoryService();
  bool _isLoading = true;
  List<CategoryModel> _rootCategories = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all categories
      final categories = await _categoryService.getCategoryTree();

      // Filter to only get root categories (level 0)
      setState(() {
        _rootCategories = categories;
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
        title: 'Shop by Category',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _buildBody(),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: const LogoLoader(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: _loadCategories,
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

    if (_rootCategories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _rootCategories.length,
      itemBuilder: (context, index) {
        return CategoryGridItem(
          category: _rootCategories[index],
          onTap: _navigateToCategory,
        );
      },
    );
  }

  void _navigateToCategory(CategoryModel category) {
    // Set this category as the root of breadcrumbs
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    productProvider.setCategoryBreadcrumbs([category]);

    // Navigate to the category tree products page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryTreeProductsPage(
          categorySlug: category.slug,
          title: category.name,
          initialBreadcrumbs: [category],
        ),
      ),
    );
  }
}

// Subcategory page to display children of a selected category
class SubcategoryPage extends StatelessWidget {
  final CategoryModel parentCategory;

  const SubcategoryPage({
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
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: parentCategory.children.length,
              itemBuilder: (context, index) {
                return CategoryGridItem(
                  category: parentCategory.children[index],
                  onTap: (category) {
                    if (category.children.isNotEmpty) {
                      // If this subcategory has children, navigate to a new subcategory page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubcategoryPage(
                            parentCategory: category,
                          ),
                        ),
                      );
                    } else {
                      // Navigate to the category tree products page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryTreeProductsPage(
                            categorySlug: category.slug,
                            title: category.name,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
