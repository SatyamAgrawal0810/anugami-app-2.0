// lib/presentation/pages/cart/widgets/empty_cart.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty cart illustration
            Container(
              width: AppTheme.isMobile(context) ? 200 : 250,
              height: AppTheme.isMobile(context) ? 200 : 250,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: AppTheme.isMobile(context) ? 80 : 100,
                color: AppTheme.textMuted,
              ),
            ),

            SizedBox(height: AppTheme.space2xl),

            // Main message
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: AppTheme.getHeadlineFontSize(context),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppTheme.spaceMd),

            // Description
            Text(
              'Looks like you haven\'t added any items to your cart yet.\nStart shopping to fill it up!',
              style: TextStyle(
                fontSize: AppTheme.getBodyFontSize(context),
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: AppTheme.space3xl),

            // Action buttons
            Column(
              children: [
                // Primary action - Continue Shopping
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.getButtonHeight(context),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/home'),
                    icon: Icon(
                      Icons.shopping_bag_outlined,
                      size: AppTheme.getIconSize(context),
                    ),
                    label: Text(
                      'Start Shopping',
                      style: TextStyle(
                        fontSize: AppTheme.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.getButtonRadius(context)),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spaceMd),

                // Secondary action - Browse Categories
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.getButtonHeight(context),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/categories'),
                    icon: Icon(
                      Icons.category_outlined,
                      size: AppTheme.getIconSize(context),
                    ),
                    label: Text(
                      'Browse Categories',
                      style: TextStyle(
                        fontSize: AppTheme.getBodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppTheme.getButtonRadius(context)),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spaceMd),

                // Tertiary action - View Wishlist
                TextButton.icon(
                  onPressed: () => context.push('/wishlist'),
                  icon: Icon(
                    Icons.favorite_outline,
                    size: AppTheme.getIconSize(context),
                  ),
                  label: Text(
                    'View Wishlist',
                    style: TextStyle(
                      fontSize: AppTheme.getBodyFontSize(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.space2xl),

            // Feature highlights
            if (!AppTheme.isMobile(context)) ...[
              Container(
                padding: AppTheme.getResponsiveCardPadding(context),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppTheme.getCardRadius(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Why shop with us?',
                      style: TextStyle(
                        fontSize: AppTheme.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppTheme.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeature(
                          context,
                          Icons.local_shipping_outlined,
                          'Free Shipping',
                          'On orders above ₹500',
                        ),
                        _buildFeature(
                          context,
                          Icons.security_outlined,
                          'Secure Payment',
                          '100% secure transactions',
                        ),
                        _buildFeature(
                          context,
                          Icons.support_agent_outlined,
                          '24/7 Support',
                          'Always here to help',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 30,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.getBodyFontSize(context),
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: AppTheme.getCaptionFontSize(context),
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
