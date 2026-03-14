// lib/presentation/pages/cart/widgets/empty_cart.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({Key? key}) : super(key: key);

  static const _kGradient = LinearGradient(
    colors: [
      Color(0xFFFEAF4E),
      Color(0xFFF96A4C),
      Color(0xFFE54481),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✨ Same as wishlist — plain circle + app_icon.png (no white tint)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.shopping_cart,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: AppTheme.space2xl),

            // Title
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

            // ── Action Buttons ──────────────────────────────────────────
            Column(
              children: [
                // ✨ Primary — gradient fill, white icon + text
                GestureDetector(
                  onTap: () => context.push('/home'),
                  child: Container(
                    width: double.infinity,
                    height: AppTheme.getButtonHeight(context),
                    decoration: BoxDecoration(
                      gradient: _kGradient,
                      borderRadius: BorderRadius.circular(
                          AppTheme.getButtonRadius(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44F96A4C),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: AppTheme.getIconSize(context)),
                        const SizedBox(width: 10),
                        Text(
                          'Start Shopping',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.getBodyFontSize(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spaceMd),

                // ✨ Secondary — gradient border, black icon + text
                GestureDetector(
                  onTap: () => context.push('/categories'),
                  child: Container(
                    width: double.infinity,
                    height: AppTheme.getButtonHeight(context),
                    decoration: BoxDecoration(
                      gradient: _kGradient,
                      borderRadius: BorderRadius.circular(
                          AppTheme.getButtonRadius(context)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            AppTheme.getButtonRadius(context) - 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined,
                              color: Colors.black87,
                              size: AppTheme.getIconSize(context)),
                          const SizedBox(width: 10),
                          Text(
                            'Browse Categories',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: AppTheme.getBodyFontSize(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spaceMd),

                // ✨ Tertiary — no border, no background, plain text + icon
                GestureDetector(
                  onTap: () => context.push('/wishlist'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline,
                          color: Colors.black87,
                          size: AppTheme.getIconSize(context)),
                      const SizedBox(width: 8),
                      Text(
                        'View Wishlist',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: AppTheme.getBodyFontSize(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppTheme.space2xl),

            // ── Feature highlights (tablet only) ────────────────────────
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
          decoration: const BoxDecoration(
            gradient: _kGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33F96A4C),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(icon, size: 28, color: Colors.white),
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