// lib/core/constants/app_constants.dart
// Production-ready constants for the application

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== ANIMATION DURATIONS ====================
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  static const Duration floatingBackgroundDuration = Duration(seconds: 30);

  // ==================== UI CONSTANTS ====================
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double largeIconSize = 64.0;
  static const double mediumIconSize = 48.0;
  static const double smallIconSize = 24.0;

  // Grid layout
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.85;
  static const double gridSpacing = 16.0;

  // Floating background
  static const int floatingIconCount = 10;
  static const double floatingIconOpacity = 0.18;
  static const double floatingIconMinSize = 18.0;
  static const double floatingIconMaxSize = 26.0;

  // ==================== SNACKBAR DURATIONS ====================
  static const Duration successSnackbarDuration = Duration(seconds: 2);
  static const Duration errorSnackbarDuration = Duration(seconds: 4);
  static const Duration infoSnackbarDuration = Duration(seconds: 3);

  // ==================== NAVIGATION ====================
  static const int homeNavIndex = 0;
  static const int categoriesNavIndex = 1;
  static const int cartNavIndex = 2;
  static const int wishlistNavIndex = 3;
  static const int profileNavIndex = 4;

  // ==================== RETRY CONFIGURATION ====================
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ==================== CACHE CONFIGURATION ====================
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // ==================== RESPONSIVE BREAKPOINTS ====================
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  // ==================== ERROR MESSAGES ====================
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String loginRequiredMessage = 'Please login to continue.';
  static const String sessionExpiredMessage =
      'Session expired. Please login again.';

  // ==================== SUCCESS MESSAGES ====================
  static const String itemAddedToCart = 'Added to cart';
  static const String itemRemovedFromCart = 'Removed from cart';
  static const String itemAddedToWishlist = 'Added to wishlist';
  static const String itemRemovedFromWishlist = 'Removed from wishlist';
  static const String cartCleared = 'Cart cleared successfully';
  static const String wishlistCleared = 'Wishlist cleared successfully';
  static const String orderPlaced = 'Order placed successfully';

  // ==================== LOADING MESSAGES ====================
  static const String loadingProducts = 'Loading products...';
  static const String loadingCart = 'Loading cart...';
  static const String loadingWishlist = 'Loading wishlist...';
  static const String loadingOrders = 'Loading orders...';
  static const String processingOrder = 'Processing your order...';
}
