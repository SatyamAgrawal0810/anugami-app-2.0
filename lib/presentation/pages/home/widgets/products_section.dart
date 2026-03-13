// lib/presentation/pages/home/widgets/products_section.dart
import 'package:flutter/material.dart';
import 'package:provider/Provider.dart';
import '../../../../core/models/product_model.dart';
import '../../../../providers/wishlist_provider.dart';
import '../../../../config/theme.dart';
import 'section_title.dart';
import 'product_card.dart';
import 'product_card_skeleton.dart';

class ProductsSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onViewAll;
  final Function(ProductModel) onProductTap;
  final Function(ProductModel)? onWishlistTap;
  final VoidCallback? onRetry;

  const ProductsSection({
    Key? key,
    required this.title,
    required this.products,
    required this.isLoading,
    this.errorMessage,
    this.onViewAll,
    required this.onProductTap,
    this.onWishlistTap,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title,
          onViewAll: onViewAll,
        ),
        SizedBox(
          height: 255, // Adjusted height to accommodate the larger product card
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductsList();
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: 4, // Show 4 skeleton cards
      itemBuilder: (context, index) {
        return const ProductCardSkeleton();
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'No products available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<WishlistProvider>(
      builder: (context, wishlistProvider, child) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productId = product.id.toString();
            final isWishlisted = wishlistProvider.isInWishlist(productId);

            // Create updated product with current wishlist status
            final updatedProduct = product.copyWith(isWishlisted: isWishlisted);

            return ProductCard(
              product: updatedProduct,
              onTap: () => onProductTap(updatedProduct),
              onWishlistTap: onWishlistTap != null
                  ? (ProductModel p) => onWishlistTap!(p)
                  : null,
            );
          },
        );
      },
    );
  }
}
