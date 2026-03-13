class ApiConfig {
  // Base URL - Apna actual backend URL yahan dalein
  static const String baseUrl = 'https://anugami.com'; // CHANGE THIS

  // API endpoints
  static const String productsEndpoint = '/api/products';
  static const String categoriesEndpoint = '/api/categories';
  static const String authEndpoint = '/api/auth';
  static const String cartEndpoint = '/api/cart';
  static const String ordersEndpoint = '/api/orders';
  static const String wishlistEndpoint = '/api/wishlist';
  static const String reviewsEndpoint = '/api/reviews';

  // API version
  static const String apiVersion = 'v1';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
