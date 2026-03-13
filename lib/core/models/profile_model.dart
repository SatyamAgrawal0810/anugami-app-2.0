// lib/core/models/profile_model.dart
class ProfileModel {
  final int id;
  final String email;
  final String phone;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? profilePicture;
  final String status;
  final String walletBalance;
  final int rewardPoints;
  final int totalOrders;
  final String totalOrderValue;
  final List<AddressModel> addresses;
  final List<CartItemModel> cartItems;
  final List<dynamic> wishlistItems;
  final PreferencesModel preferences;
  final String createdAt;
  final String updatedAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.profilePicture,
    required this.status,
    required this.walletBalance,
    required this.rewardPoints,
    required this.totalOrders,
    required this.totalOrderValue,
    required this.addresses,
    required this.cartItems,
    required this.wishlistItems,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    print("Creating ProfileModel from JSON: ${json.keys}");

    // Debug each field type before conversion
    json.forEach((key, value) {
      print("Field '$key': value=$value, type=${value?.runtimeType}");
    });

    try {
      final id = json['id'] ?? 0;
      print("Processing id: $id (${id.runtimeType})");

      final email = json['email'] ?? '';
      print("Processing email: $email (${email.runtimeType})");

      final rewardPoints = json['reward_points'] ?? 0;
      print(
          "Processing reward_points: $rewardPoints (${rewardPoints.runtimeType})");

      final totalOrders = json['total_orders'] ?? 0;
      print(
          "Processing total_orders: $totalOrders (${totalOrders.runtimeType})");

      // Handle nested objects with careful debugging
      print("Processing addresses array");
      final addressesJson = json['addresses'] as List<dynamic>? ?? [];
      final addresses = addressesJson.map((addressJson) {
        try {
          return AddressModel.fromJson(addressJson);
        } catch (e) {
          print("Error parsing address: $e");
          print("Address data: $addressJson");
          return AddressModel.empty(); // Fallback to empty
        }
      }).toList();

      print("Processing cart_items array");
      final cartItemsJson = json['cart_items'] as List<dynamic>? ?? [];
      final cartItems = cartItemsJson.map((itemJson) {
        try {
          return CartItemModel.fromJson(itemJson);
        } catch (e) {
          print("Error parsing cart item: $e");
          print("Cart item data: $itemJson");
          return CartItemModel.empty(); // Fallback to empty
        }
      }).toList();

      print("Processing preferences object");
      PreferencesModel preferences;
      try {
        preferences = json['preferences'] != null
            ? PreferencesModel.fromJson(json['preferences'])
            : PreferencesModel.empty();
      } catch (e) {
        print("Error parsing preferences: $e");
        print("Preferences data: ${json['preferences']}");
        preferences = PreferencesModel.empty();
      }

      return ProfileModel(
        id: id,
        email: email,
        phone: json['phone'] ?? '',
        fullName: json['full_name'] ?? '',
        dateOfBirth: json['date_of_birth'],
        gender: json['gender'],
        profilePicture: json['profile_picture'],
        status: json['status'] ?? 'inactive',
        walletBalance: (json['wallet_balance'] ?? '0.00').toString(),
        rewardPoints: rewardPoints,
        totalOrders: totalOrders,
        totalOrderValue: (json['total_order_value'] ?? '0.00').toString(),
        addresses: addresses,
        cartItems: cartItems,
        wishlistItems: json['wishlist_items'] ?? [],
        preferences: preferences,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );
    } catch (e, stackTrace) {
      print("Error creating ProfileModel: $e");
      print("Stack trace: $stackTrace");
      rethrow; // Rethrow to see the error in the UI
    }
  }
}

class AddressModel {
  final int id;
  final String addressType;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isDefault;
  final int customer;

  AddressModel({
    required this.id,
    required this.addressType,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.isDefault,
    required this.customer,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    print("Creating AddressModel from JSON: ${json.keys}");
    try {
      return AddressModel(
        id: json['id'] ?? 0,
        addressType: json['address_type'] ?? '',
        fullName: json['full_name'] ?? '',
        phone: json['phone'] ?? '',
        street: json['street'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        country: json['country'] ?? '',
        pincode: json['pincode'] ?? '',
        isDefault: json['is_default'] ?? false,
        customer: json['customer'] ?? 0,
      );
    } catch (e) {
      print("Error in AddressModel.fromJson: $e");
      print("JSON: $json");
      rethrow;
    }
  }

  // Create an empty model for fallback
  factory AddressModel.empty() {
    return AddressModel(
      id: 0,
      addressType: '',
      fullName: '',
      phone: '',
      street: '',
      city: '',
      state: '',
      country: '',
      pincode: '',
      isDefault: false,
      customer: 0,
    );
  }
}

class CartItemModel {
  final int id;
  final int productId;
  final int? variantId;
  final int quantity;
  final String price;
  final String totalPrice;
  final String addedAt;
  final String updatedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    print("Creating CartItemModel from JSON: ${json.keys}");
    try {
      // Debug the types of potentially problematic fields
      final id = json['id'];
      print("Cart item id: $id (${id.runtimeType})");

      final productId = json['product_id'];
      print("Cart item product_id: $productId (${productId.runtimeType})");

      final variantId = json['variant_id'];
      print("Cart item variant_id: $variantId (${variantId?.runtimeType})");

      final quantity = json['quantity'];
      print("Cart item quantity: $quantity (${quantity.runtimeType})");

      final price = json['price'];
      print("Cart item price: $price (${price.runtimeType})");

      final totalPrice = json['total_price'];
      print("Cart item total_price: $totalPrice (${totalPrice.runtimeType})");

      return CartItemModel(
        id: id ?? 0,
        productId: productId ?? 0,
        variantId: variantId,
        quantity: quantity ?? 0,
        price: (price ?? '0.00').toString(),
        totalPrice: (totalPrice ?? '0.00').toString(),
        addedAt: json['added_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
      );
    } catch (e) {
      print("Error in CartItemModel.fromJson: $e");
      print("JSON: $json");
      rethrow;
    }
  }

  // Create an empty model for fallback
  factory CartItemModel.empty() {
    return CartItemModel(
      id: 0,
      productId: 0,
      variantId: null,
      quantity: 0,
      price: '0.00',
      totalPrice: '0.00',
      addedAt: '',
      updatedAt: '',
    );
  }
}

class PreferencesModel {
  final int id;
  final String currency;
  final String language;
  final Map<String, dynamic> notificationPreferences;
  final Map<String, dynamic> marketingPreferences;
  final int customer;

  PreferencesModel({
    required this.id,
    required this.currency,
    required this.language,
    required this.notificationPreferences,
    required this.marketingPreferences,
    required this.customer,
  });

  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    print("Creating PreferencesModel from JSON: ${json.keys}");
    try {
      final id = json['id'];
      print("Preferences id: $id (${id.runtimeType})");

      final customer = json['customer'];
      print("Preferences customer: $customer (${customer.runtimeType})");

      return PreferencesModel(
        id: id ?? 0,
        currency: json['currency'] ?? 'INR',
        language: json['language'] ?? 'en',
        notificationPreferences: json['notification_preferences'] ?? {},
        marketingPreferences: json['marketing_preferences'] ?? {},
        customer: customer ?? 0,
      );
    } catch (e) {
      print("Error in PreferencesModel.fromJson: $e");
      print("JSON: $json");
      rethrow;
    }
  }

  factory PreferencesModel.empty() {
    return PreferencesModel(
      id: 0,
      currency: 'INR',
      language: 'en',
      notificationPreferences: {},
      marketingPreferences: {},
      customer: 0,
    );
  }
}
