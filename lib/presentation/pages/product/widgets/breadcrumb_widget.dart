// lib/presentation/widgets/breadcrumb_widget.dart
import 'package:anu_app/core/models/breadcrumb_model.dart';
import 'package:flutter/material.dart';

class BreadcrumbWidget extends StatelessWidget {
  final List<BreadcrumbModel> breadcrumbs;
  final Function(String) onTap;

  const BreadcrumbWidget({
    Key? key,
    required this.breadcrumbs,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: () => onTap(''),
              child: const Text(
                'Home',
                style: TextStyle(
                  color: Color(0xFFFEAF4E),
                  fontSize: 14,
                ),
              ),
            ),
            ...breadcrumbs.asMap().entries.expand((entry) {
              final index = entry.key;
              final breadcrumb = entry.value;

              // Return a list containing the separator and the breadcrumb
              return [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '/',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
                InkWell(
                  onTap: () => onTap(breadcrumb.slug),
                  child: Text(
                    breadcrumb.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: index == breadcrumbs.length - 1
                          ? Colors.black
                          : const Color(0xFFFEAF4E),
                      fontWeight: index == breadcrumbs.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ];
            }).toList(),
          ],
        ),
      ),
    );
  }
}
