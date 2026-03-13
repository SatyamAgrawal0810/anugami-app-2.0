// lib/presentation/pages/categories/widgets/category_grid_item.dart
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/category_model.dart';

class CategoryGridItem extends StatelessWidget {
  final CategoryModel category;
  final Function(CategoryModel) onTap;

  const CategoryGridItem({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category image or icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: category.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.network(
                        category.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getCategoryIcon(),
                            color: AppTheme.primaryGradient.colors[1],
                            size: 35,
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(),
                      color: AppTheme.primaryGradient.colors[1],
                      size: 35,
                    ),
            ),
            const SizedBox(height: 12),
            // Category name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Removed subcategories count display
          ],
        ),
      ),
    );
  }

  // Helper method to get an appropriate icon based on category name
  IconData _getCategoryIcon() {
    final categoryName = category.name.toLowerCase();

    if (categoryName.contains('men') ||
        categoryName.contains('shirt') ||
        categoryName.contains('clothing')) {
      return Icons.checkroom;
    } else if (categoryName.contains('electronic') ||
        categoryName.contains('device') ||
        categoryName.contains('tech')) {
      return Icons.devices;
    } else if (categoryName.contains('food') ||
        categoryName.contains('grocery') ||
        categoryName.contains('fruit')) {
      return Icons.shopping_basket;
    } else if (categoryName.contains('home') ||
        categoryName.contains('furniture') ||
        categoryName.contains('decor')) {
      return Icons.home;
    } else if (categoryName.contains('beauty') ||
        categoryName.contains('makeup') ||
        categoryName.contains('cosmetic')) {
      return Icons.face;
    } else if (categoryName.contains('sport') ||
        categoryName.contains('fitness') ||
        categoryName.contains('exercise')) {
      return Icons.sports_soccer;
    } else if (categoryName.contains('book') ||
        categoryName.contains('reading')) {
      return Icons.book;
    } else if (categoryName.contains('jewelry') ||
        categoryName.contains('accessory')) {
      return Icons.watch;
    } else if (categoryName.contains('toy') || categoryName.contains('game')) {
      return Icons.toys;
    } else if (categoryName.contains('baby') || categoryName.contains('kid')) {
      return Icons.child_care;
    }

    // Default icon
    return Icons.category;
  }
}
