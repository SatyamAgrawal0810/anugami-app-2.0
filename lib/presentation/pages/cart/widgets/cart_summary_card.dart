// lib/presentation/pages/cart/widgets/cart_summary_card.dart
import 'package:flutter/material.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../config/theme.dart';

class CartSummaryCard extends StatelessWidget {
  final CartProvider cartProvider;
  final VoidCallback onCheckout;
  final bool isCompact;

  const CartSummaryCard({
    Key? key,
    required this.cartProvider,
    required this.onCheckout,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedCount = cartProvider.selectedCount;
    final hasSelection = selectedCount > 0;

    return SizedBox(
      width: double.infinity,
      height: AppTheme.getButtonHeight(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: hasSelection
              ? AppTheme.primaryGradient
              : LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                ),
          borderRadius:
              BorderRadius.circular(AppTheme.getButtonRadius(context)),
        ),
        child: ElevatedButton(
          onPressed: hasSelection ? onCheckout : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.getButtonRadius(context)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: AppTheme.getSmallIconSize(context),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                hasSelection
                    ? 'Proceed to Checkout ($selectedCount item${selectedCount == 1 ? '' : 's'})'
                    : 'Select Items to Checkout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.getBodyFontSize(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
