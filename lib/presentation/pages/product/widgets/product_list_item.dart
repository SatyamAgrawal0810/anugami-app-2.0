// lib/presentation/pages/product/widgets/product_list_item.dart
import 'package:anu_app/providers/product_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/product_model.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onWishlistTap;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            height: 120, // Fixed height to prevent overflow
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image and discount badge
                Stack(
                  children: [
                    // Product image - Fixed size
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: product.primaryImageUrl.isNotEmpty
                            ? Image.network(
                                product.primaryImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, error, _) => Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: LogoLoader(),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
                      ),
                    ),

                    // Discount badge
                    if (product.discountPercentage.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4947),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            product.discountPercentage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Product details
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name - Fixed to 2 lines
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Seller name if available
                      if (product.sellerInfo != null)
                        Text(
                          'by ${product.sellerInfo!.userName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const Spacer(),

                      // Price section - Single line
                      Row(
                        children: [
                          Text(
                            product.formattedSalePrice,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.discountPercentage.isNotEmpty)
                            Flexible(
                              child: Text(
                                product.formattedRegularPrice,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Stock status - Single line
                      Row(
                        children: [
                          Icon(
                            product.stockQuantity > 0
                                ? Icons.check_circle
                                : Icons.error,
                            size: 12,
                            color: product.stockQuantity > 0
                                ? const Color(0xFFF96A4C)
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.stockQuantity > 0
                                ? 'In Stock'
                                : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: product.stockQuantity > 0
                                  ? const Color(0xFFF96A4C)
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Wishlist button - Fixed size
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final isWishlisted =
                        wishlistProvider.isInWishlist(product.id.toString());

                    return IconButton(
                      onPressed: () async {
                        await Provider.of<ProductProvider>(context,
                                listen: false)
                            .toggleWishlist(product, context);
                      },
                      icon: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted
                            ? const Color(0xFFFF4947)
                            : Colors.grey,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: const EdgeInsets.all(8),
                      splashRadius: 20,
                      tooltip: isWishlisted
                          ? 'Remove from Wishlist'
                          : 'Add to Wishlist',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
