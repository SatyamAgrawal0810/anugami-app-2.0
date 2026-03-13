// lib/config/routes.dart
// ✅ COMPLETE UPDATED VERSION - Guest Mode Support (Meesho-style)
import 'package:anu_app/presentation/widgets/reviews/review_form.dart';
import 'package:anu_app/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/create_account_page.dart';
import '../presentation/pages/auth/forgot_password_page.dart';
import '../presentation/pages/auth/reset_password_page.dart';
import '../presentation/pages/auth/address_form_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/wishlist/wishlist_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/profile/my_addresses_page.dart';
import '../presentation/pages/profile/widgets/edit_profile_page.dart';
import '../presentation/pages/categories/combined_categories_page.dart';
import '../presentation/pages/categories/category_tree_products_page.dart';
import '../presentation/pages/product/product_detail_page.dart';
import '../presentation/pages/product/products_page.dart';
import '../presentation/pages/cart/cart_page.dart';
import '../presentation/pages/coupons/coupons_page.dart';
import '../presentation/pages/cart/checkout_page.dart';
import '../presentation/pages/orders/order_history_page.dart';
import '../presentation/pages/contact/contact_us_page.dart';
import '../core/models/profile_model.dart';
import '../presentation/pages/profile/widgets/notification_preference_page.dart';
import '../presentation/pages/brand/brand_details_page.dart';
import '../presentation/pages/orders/order_details_page.dart';
import '../presentation/pages/categories/google_categories_enhanced.dart';

class AppRoutes {
  // ✅ UPDATED: Guest mode support with redirect handling
  static GoRouter createRouter({
    required bool isLoggedIn,
    required Listenable refreshListenable,
  }) {
    return GoRouter(
      // ✅ CHANGED: Always start from home, not login
      // This allows guest users to browse without authentication
      initialLocation: '/home',
      debugLogDiagnostics: true,

      // ✅ This makes router reactive to auth state changes
      refreshListenable: refreshListenable,

      // ✅ UPDATED: Smart redirect logic for guest mode
      redirect: (context, state) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentAuthState = userProvider.isLoggedIn;

        // Auth routes (always accessible)
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/create-account' ||
            state.matchedLocation == '/forgot-password' ||
            state.matchedLocation.startsWith('/reset-password');

        // ✅ PUBLIC ROUTES - No authentication required
        // These routes are accessible to everyone (guest or logged-in)
        final isPublicRoute = state.matchedLocation == '/home' ||
            state.matchedLocation == '/search' ||
            state.matchedLocation == '/cart' ||
            state.matchedLocation == '/checkout' || // ✅ Checkout is public now!
            state.matchedLocation == '/categories' ||
            state.matchedLocation.startsWith('/category-products') ||
            state.matchedLocation.startsWith('/product') ||
            state.matchedLocation.startsWith('/products') ||
            state.matchedLocation == '/contact';

        // ✅ PROTECTED ROUTES - Authentication required
        // These routes require user to be logged in
        final isProtectedRoute = state.matchedLocation == '/orders' ||
            state.matchedLocation == '/profile' ||
            state.matchedLocation == '/wishlist' ||
            state.matchedLocation.startsWith('/profile/') ||
            state.matchedLocation == '/address-form' ||
            state.matchedLocation == '/notification-preferences';

        // ✅ REDIRECT LOGIC

        // If user tries to access protected route without login
        if (isProtectedRoute && !currentAuthState) {
          // Save intended destination for redirect after login
          return '/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
        }

        // If logged-in user tries to access auth pages
        if (currentAuthState &&
            (state.matchedLocation == '/login' ||
                state.matchedLocation == '/create-account')) {
          // Check if there's a redirect URL
          final redirectUrl = state.uri.queryParameters['redirect'];
          if (redirectUrl != null && redirectUrl.isNotEmpty) {
            return Uri.decodeComponent(redirectUrl);
          }
          // Otherwise go to home
          return '/home';
        }

        // Allow navigation for all other cases
        return null;
      },

      routes: [
        // ==================== AUTHENTICATION ROUTES ====================

        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),

        GoRoute(
          path: '/create-account',
          name: 'create-account',
          builder: (context, state) => const CreateAccountPage(),
        ),

        // Password Reset Routes
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => ResetPasswordPage(
            initialEmail: state.extra as String?, // ✅ email receive karo
          ),
        ),
        // ==================== PUBLIC ROUTES ====================
        // These routes don't require authentication

        // Home Page
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),

        // Search Page
        GoRoute(
          path: '/search',
          name: 'search',
          builder: (context, state) {
            final query = state.uri.queryParameters['q'] ?? '';
            return SearchPage(initialQuery: query);
          },
        ),

        // Category Routes
        GoRoute(
          path: '/categories',
          name: 'categories',
          builder: (context, state) => const ImageCategoriesThemed(),
        ),

        GoRoute(
          path: '/category-products/:slug',
          name: 'category-products',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            final title =
                state.uri.queryParameters['title'] ?? 'Category Products';
            return CategoryTreeProductsPage(
              categorySlug: slug,
              title: title,
            );
          },
        ),

        // Product Routes
        GoRoute(
          path: '/product/:slug',
          name: 'product-detail',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return ProductDetailPage(slug: slug);
          },
        ),

        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) {
            final type = state.uri.queryParameters['type'] ?? '';
            final title = state.uri.queryParameters['title'] ?? 'Products';
            final category = state.uri.queryParameters['category'];
            return ProductsPage(
              type: type,
              title: title,
              categorySlug: category,
            );
          },
        ),

        // ✅ CART ROUTES - PUBLIC (Guest users can access)
        GoRoute(
          path: '/cart',
          name: 'cart',
          builder: (context, state) => const CartPage(),
        ),

        // ✅ CHECKOUT - PUBLIC (Auth check happens at payment time)
        // In lib/config/routes.dart:

        GoRoute(
          path: '/checkout',
          builder: (context, state) {
            final params = state.uri.queryParameters;

            if (params['buyNow'] == 'true') {
              return CheckoutPage(
                buyNowProductId: params['productId'],
                buyNowProductName: params['productName'],
                buyNowPrice: params['price'],
                buyNowRegularPrice: params['regularPrice'], // ✅ NEW
                buyNowImage: params['image'],
                buyNowVariantId: params['variantId'],
                buyNowColor: params['color'],
                buyNowSize: params['size'],
              );
            }

            return const CheckoutPage();
          },
        ),

// Add coupons route:
        GoRoute(
          path: '/coupons',
          builder: (context, state) => const CouponsPage(),
        ),
        // Contact & Support Routes
        GoRoute(
          path: '/contact',
          name: 'contact',
          builder: (context, state) => const ContactUsPage(),
        ),

        // Redirect old routes to contact
        GoRoute(
          path: '/help',
          name: 'help',
          redirect: (context, state) => '/contact',
        ),
        GoRoute(
          path: '/faq',
          name: 'faq',
          redirect: (context, state) => '/contact',
        ),
        GoRoute(
          path: '/support',
          name: 'support',
          redirect: (context, state) => '/contact',
        ),
        GoRoute(
          path: '/brands/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return BrandDetailsPage(brandSlug: slug);
          },
        ),
        // Review Routes
        GoRoute(
          path: '/product/:slug/review',
          name: 'write-review',
          builder: (context, state) {
            final slug = state.pathParameters['slug']!;
            return ReviewForm(
              productSlug: slug,
              onSuccess: () {
                context.pop();
              },
            );
          },
        ),

        // ==================== PROTECTED ROUTES ====================
        // These routes require authentication
        GoRoute(
          path: '/coupons',
          name: 'coupons',
          builder: (context, state) => const CouponsPage(),
        ),
        // Wishlist (Protected)
        GoRoute(
          path: '/wishlist',
          name: 'wishlist',
          builder: (context, state) => const WishlistPage(),
        ),

        // Orders (Protected)
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrderHistoryPage(),
        ),

        // Profile Routes (Protected)
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/orders/:id',
          name: 'order-detail',
          builder: (context, state) {
            final orderId = int.parse(state.pathParameters['id']!);
            return OrderDetailsPage(orderId: orderId.toString());
          },
        ),
        GoRoute(
          path: '/profile/edit',
          name: 'profile-edit',
          builder: (context, state) {
            final profileData = state.extra as ProfileModel?;
            if (profileData == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Profile data not found'),
                ),
              );
            }
            return EditProfilePage(profile: profileData);
          },
        ),

        GoRoute(
          path: '/profile/addresses',
          name: 'profile-addresses',
          builder: (context, state) => const MyAddressesPage(),
        ),

        // Notification Preferences (Protected)
        GoRoute(
          path: '/notification-preferences',
          name: 'notification-preferences',
          builder: (context, state) => const NotificationPreferencePage(),
        ),

        // Address Form (Protected)
        GoRoute(
          path: '/address-form',
          name: 'address-form',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'] ?? 'newAddress';
            final fullName = state.uri.queryParameters['fullName'];
            final phone = state.uri.queryParameters['phone'];

            AddressFormMode addressMode;
            if (mode == 'registration') {
              addressMode = AddressFormMode.registration;
            } else if (mode == 'editAddress') {
              addressMode = AddressFormMode.editAddress;
            } else {
              addressMode = AddressFormMode.newAddress;
            }

            return AddressFormPage(
              mode: addressMode,
              fullName: fullName,
              phone: phone,
            );
          },
        ),
      ],

      // Error handling with better UX
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          backgroundColor: const Color(0xFFFEAF4E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Page Not Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The page "${state.matchedLocation}" could not be found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEAF4E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Go Home'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () => context.push('/cart'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFEAF4E),
                        side: const BorderSide(color: Color(0xFFFEAF4E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Cart'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFEAF4E),
                    side: const BorderSide(color: Color(0xFFFEAF4E)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Contact Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== NAVIGATION HELPER METHODS ====================

  static void goToCart(BuildContext context) {
    context.push('/cart');
  }

  static void goToCheckout(BuildContext context) {
    context.push('/checkout');
  }

  static void goToProduct(BuildContext context, String slug) {
    context.push('/product/$slug');
  }

  static void goToOrders(BuildContext context) {
    context.push('/orders');
  }

  static void goToCategory(BuildContext context, String slug, String title) {
    context
        .push('/category-products/$slug?title=${Uri.encodeComponent(title)}');
  }

  static void goToProducts(
    BuildContext context, {
    String type = '',
    String title = 'Products',
    String? category,
  }) {
    var uri =
        '/products?type=${Uri.encodeComponent(type)}&title=${Uri.encodeComponent(title)}';
    if (category != null) {
      uri += '&category=${Uri.encodeComponent(category)}';
    }
    context.push(uri);
  }

  static void goToProfile(BuildContext context) {
    context.push('/profile');
  }

  static void goToWishlist(BuildContext context) {
    context.push('/wishlist');
  }

  static void goToHome(BuildContext context) {
    context.push('/home');
  }

  static void goToSearch(BuildContext context, String query) {
    context.push('/search?q=${Uri.encodeComponent(query)}');
  }

  static void goToContact(BuildContext context) {
    context.push('/contact');
  }

  static void goToForgotPassword(BuildContext context) {
    context.push('/forgot-password');
  }

  static void goToResetPassword(BuildContext context, String token) {
    context.push('/reset-password/$token');
  }

  // ✅ UPDATED: Login with redirect support
  static void goToLogin(BuildContext context, {String? redirectTo}) {
    if (redirectTo != null && redirectTo.isNotEmpty) {
      context.push('/login?redirect=${Uri.encodeComponent(redirectTo)}');
    } else {
      context.push('/login');
    }
  }

  // Back navigation with fallback
  static void goBack(BuildContext context, {String fallbackRoute = '/home'}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.push(fallbackRoute);
    }
  }
}
