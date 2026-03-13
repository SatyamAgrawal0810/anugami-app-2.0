// lib/presentation/pages/categories/widgets/animated_category_list.dart
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/category_model.dart';

class AnimatedCategoryList extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategoryTap;

  const AnimatedCategoryList({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  State<AnimatedCategoryList> createState() => _AnimatedCategoryListState();
}

class _AnimatedCategoryListState extends State<AnimatedCategoryList> {
  final Map<String, bool> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.categories.length,
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final isExpanded = _expandedCategories[category.id] ?? false;
        final hasChildren = category.children.isNotEmpty;

        return Column(
          children: [
            // Main category item
            _buildCategoryItem(category, isExpanded, hasChildren),

            // Animated subcategories
            if (hasChildren)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isExpanded ? (category.children.length * 48.0) : 0,
                curve: Curves.easeInOut,
                child: isExpanded
                    ? ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: category.children.length,
                        itemBuilder: (context, subIndex) {
                          final subcategory = category.children[subIndex];
                          return _buildSubcategoryItem(subcategory);
                        },
                      )
                    : Container(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(
      CategoryModel category, bool isExpanded, bool hasChildren) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          if (hasChildren) {
            setState(() {
              _expandedCategories[category.id] = !isExpanded;
            });
          } else {
            widget.onCategoryTap(category);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Category image or icon
              if (category.imageUrl != null)
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(category.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category.name),
                    color: AppTheme.primaryGradient.colors[1],
                    size: 24,
                  ),
                ),

              // Category name and product count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Removed subcategory count display
                  ],
                ),
              ),

              // Expand/collapse icon or navigate icon
              AnimatedRotation(
                turns: isExpanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hasChildren
                      ? Icons.arrow_forward_ios
                      : Icons.arrow_forward_ios,
                  color: AppTheme.primaryGradient.colors[1],
                  size: hasChildren ? 14 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoryItem(CategoryModel subcategory) {
    final hasChildren = subcategory.children.isNotEmpty;

    return Material(
      color: Colors.grey.shade50,
      child: InkWell(
        onTap: () => widget.onCategoryTap(subcategory),
        child: Container(
          padding:
              const EdgeInsets.only(left: 72, right: 16, top: 14, bottom: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subcategory.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppTheme.primaryGradient.colors[1],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get an appropriate icon based on category name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('men') ||
        name.contains('shirt') ||
        name.contains('clothing')) {
      return Icons.checkroom;
    } else if (name.contains('electronic') ||
        name.contains('device') ||
        name.contains('tech')) {
      return Icons.devices;
    } else if (name.contains('food') ||
        name.contains('grocery') ||
        name.contains('fruit')) {
      return Icons.shopping_basket;
    } else if (name.contains('home') ||
        name.contains('furniture') ||
        name.contains('decor')) {
      return Icons.home;
    } else if (name.contains('beauty') ||
        name.contains('makeup') ||
        name.contains('cosmetic')) {
      return Icons.face;
    } else if (name.contains('sport') ||
        name.contains('fitness') ||
        name.contains('exercise')) {
      return Icons.sports_soccer;
    }

    // Default icon
    return Icons.category;
  }
}
