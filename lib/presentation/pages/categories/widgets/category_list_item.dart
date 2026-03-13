// lib/presentation/pages/categories/widgets/category_list_item.dart
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/category_model.dart';

class CategoryListItem extends StatefulWidget {
  final CategoryModel category;
  final Function(CategoryModel) onTap;

  const CategoryListItem({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<CategoryListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Determine if this category has children
    final bool hasChildren = widget.category.children.isNotEmpty;

    return Column(
      children: [
        // Main category item
        InkWell(
          onTap: () {
            if (hasChildren) {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            } else {
              widget.onTap(widget.category);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (widget.category.imageUrl != null)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(widget.category.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category,
                      color: Colors.grey.shade400,
                    ),
                  ),
                // In the build method, update the section where we display category information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Removed subcategory count display
                    ],
                  ),
                ),
                if (hasChildren)
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryGradient.colors[1],
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.primaryGradient.colors[1],
                  ),
              ],
            ),
          ),
        ),

        // Children (subcategories)
        if (_isExpanded && hasChildren)
          Container(
            color: Colors.grey.shade50,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.category.children.length,
              itemBuilder: (context, index) {
                final subcategory = widget.category.children[index];
                return _buildSubcategoryItem(subcategory);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategoryItem(CategoryModel subcategory) {
    // Check if this subcategory has children
    final bool hasChildren = subcategory.children.isNotEmpty;

    return InkWell(
      onTap: () {
        widget.onTap(subcategory);
      },
      child: Container(
        padding:
            const EdgeInsets.only(left: 72, right: 16, top: 10, bottom: 10),
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
              size: 14,
              color: AppTheme.primaryGradient.colors[1],
            ),
          ],
        ),
      ),
    );
  }
}
