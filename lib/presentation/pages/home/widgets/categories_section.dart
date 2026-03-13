// lib/presentation/pages/home/widgets/categories_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../api/services/category_service.dart';
import '../../../../core/models/category_model.dart';
import '../../../../config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'section_title.dart'; // ViewAllButton

class CategoriesSection extends StatefulWidget {
  final Function(CategoryModel)? onCategoryTap;
  const CategoriesSection({Key? key, this.onCategoryTap}) : super(key: key);

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection>
    with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  // ── View All animation ─────────────────────────────────────────────────────
  late AnimationController _viewAllController;
  late Animation<double> _viewAllAnim;

  @override
  void initState() {
    super.initState();
    _viewAllController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _viewAllAnim =
        CurvedAnimation(parent: _viewAllController, curve: Curves.easeOut);
    _loadCategories();
  }

  @override
  void dispose() {
    _viewAllController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategoryTree();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _onViewAllTap() async {
    await _viewAllController.forward();
    if (mounted) context.push('/categories');
    if (mounted) _viewAllController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // ✅ matches updated ViewAllButton signature (anim + onTap only)
              ViewAllButton(
                anim: _viewAllAnim,
                onTap: _onViewAllTap,
              ),
            ],
          ),
        ),
        _buildCategoriesContent(),
      ],
    );
  }

  Widget _buildCategoriesContent() {
    if (_isLoading) {
      return const SizedBox(height: 160, child: Center(child: LogoLoader()));
    }
    if (_error != null) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('Failed to load categories',
              style: TextStyle(color: Colors.red[400])),
        ),
      );
    }
    if (_categories.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text('No categories available',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return CategoryItem(
            category: category,
            onTap: () {
              if (widget.onCategoryTap != null) {
                widget.onCategoryTap!(category);
              } else {
                context.push(
                    '/category-products/${category.slug}?title=${category.name}');
              }
            },
          );
        },
      ),
    );
  }
}

// ── Category Item ─────────────────────────────────────────────────────────────
class CategoryItem extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryItem({Key? key, required this.category, required this.onTap})
      : super(key: key);

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 110,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CategoryImageCard(category: widget.category),
              const SizedBox(height: 8),
              Text(
                widget.category.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Image Card ───────────────────────────────────────────────────────
class _CategoryImageCard extends StatelessWidget {
  final CategoryModel category;
  const _CategoryImageCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final url = (category.iconUrl != null && category.iconUrl!.isNotEmpty)
        ? category.iconUrl!
        : (category.imageUrl != null && category.imageUrl!.isNotEmpty)
            ? category.imageUrl!
            : null;

    if (url != null) {
      return Image.network(
        url,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Icon(_getCategoryIcon(), color: Colors.white, size: 40),
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    final name = category.name.toLowerCase();
    if (name.contains('men') ||
        name.contains('shirt') ||
        name.contains('clothing')) return Icons.checkroom;
    if (name.contains('electronic') ||
        name.contains('device') ||
        name.contains('tech')) return Icons.devices;
    if (name.contains('food') ||
        name.contains('grocery') ||
        name.contains('fruit')) return Icons.shopping_basket;
    if (name.contains('home') ||
        name.contains('living') ||
        name.contains('furniture') ||
        name.contains('decor')) return Icons.home;
    if (name.contains('beauty') ||
        name.contains('makeup') ||
        name.contains('cosmetic')) return Icons.face;
    if (name.contains('sport') ||
        name.contains('fitness') ||
        name.contains('exercise')) return Icons.sports_soccer;
    return Icons.category;
  }
}
