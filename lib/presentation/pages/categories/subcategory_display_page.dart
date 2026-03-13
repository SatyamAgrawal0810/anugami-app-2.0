// lib/presentation/pages/categories/subcategory_display_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/config/theme.dart';
import '../../../core/models/category_model.dart';
import '../../../providers/optimized_product_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';

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
