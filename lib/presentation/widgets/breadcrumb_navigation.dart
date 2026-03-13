// lib/presentation/widgets/breadcrumb_navigation.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/category_model.dart';

class BreadcrumbNavigation extends StatelessWidget {
  final List<CategoryModel> breadcrumbs;
  final Function(CategoryModel, int) onBreadcrumbTap;

  const BreadcrumbNavigation({
    super.key,
    required this.breadcrumbs,
    required this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Home link
            InkWell(
              onTap: () {
                // Navigate to home
                context.push('/home');
              },
              child: const Text(
                'Home',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),

            // Add breadcrumbs with separators
            for (int i = 0; i < breadcrumbs.length; i++) ...[
              // Separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),

              // Breadcrumb item
              InkWell(
                onTap: i < breadcrumbs.length - 1
                    ? () => onBreadcrumbTap(breadcrumbs[i], i)
                    : null,
                child: Text(
                  breadcrumbs[i].name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: i == breadcrumbs.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: i < breadcrumbs.length - 1
                        ? AppTheme.primaryColor
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
