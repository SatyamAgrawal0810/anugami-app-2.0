// lib/presentation/pages/orders/widgets/order_item_card.dart
// ✅ FIX: Uses item.image (direct URL from API) instead of guessing URLs
// ✅ Shows variantValues chips, regularPrice strikethrough, itemDiscount badge

import 'package:flutter/material.dart';
import '../../../../core/models/order_model.dart';
import '../../../../config/theme.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem item;

  const OrderItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ───────────────────────────────────────────────────────────
          _buildImage(),
          const SizedBox(width: 12),

          // ── Details ─────────────────────────────────────────────────────────
          Expanded(child: _buildDetails()),
        ],
      ),
    );
  }

  // ✅ FIX: Use item.image directly — no more URL guessing
  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade100,
        child: item.image != null && item.image!.isNotEmpty
            ? Image.network(
                item.image!,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              color: Colors.grey.shade400, size: 36),
          const SizedBox(height: 4),
          Text('Product',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          item.name,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // SKU
        if (item.sku != null && item.sku!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _chip(
              label: 'SKU: ${item.sku!}', color: Colors.blue, icon: Icons.tag),
        ],

        // ✅ Variant chips from variantValues dict
        if (item.variantValues != null && item.variantValues!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: item.variantValues!.entries.map((e) {
              Color c;
              switch (e.key.toLowerCase()) {
                case 'color':
                case 'colour':
                  c = Colors.purple;
                  break;
                case 'size':
                  c = Colors.orange;
                  break;
                default:
                  c = Colors.teal;
              }
              return _chip(label: '${e.key}: ${e.value}', color: c);
            }).toList(),
          ),
        ],

        const SizedBox(height: 10),

        // ── Pricing ──────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildPricing()),
            _buildTotal(),
          ],
        ),

        // ✅ Coupon savings badge (item-level)
        if (item.itemDiscount != null && item.itemDiscount! > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green.shade200, width: 0.5),
            ),
            child: Text(
              'Coupon saved ₹${item.itemDiscount!.round()} on this item',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPricing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Qty
        Text(
          'Qty: ${item.quantity}',
          style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),

        // ✅ MRP strikethrough + discount badge (uses regularPrice from serializer)
        if (item.hasDiscount) ...[
          Row(
            children: [
              Text(
                '₹${item.mrp.round()}',
                style: TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF96A4C),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${item.discountPercent}% OFF',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        // Sale price (gradient)
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            '₹${item.effectivePrice.round()}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildTotal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Total',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          item.formattedTotalValue,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor),
        ),
      ],
    );
  }

  Widget _chip({required String label, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color.withOpacity(0.7)),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
