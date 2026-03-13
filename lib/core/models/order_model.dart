// lib/core/models/order_model.dart

double parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int parseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class OrderModel {
  final int id;
  final String orderNumber;
  final int userId;
  final int sellerId;
  final String status;
  final double totalAmount;

  final String? promoCode;
  final double? subtotal;
  final double? discountAmount;
  final double? finalAmount;
  final double? discount;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool canCancel;
  final DateTime? cancelWindowEndsAt;
  final List<OrderItem> items;
  final List<OrderAddress> addresses;
  final ShippingDetails? shipping;
  final PaymentDetails? payment;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.sellerId,
    required this.status,
    required this.totalAmount,
    this.promoCode,
    this.subtotal,
    this.discountAmount,
    this.finalAmount,
    this.discount,
    required this.createdAt,
    required this.updatedAt,
    required this.canCancel,
    required this.cancelWindowEndsAt,
    required this.items,
    required this.addresses,
    this.shipping,
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // ══ DEBUG ══════════════════════════════════════════════════════════════
    final orderNum = json['order_number'] ?? json['id'];
    final paymentRaw = json['payment'];
    final itemsRaw = json['items'] as List? ?? [];
    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📦 ORDER: $orderNum  |  status: ${json['status']}');
    print('   total_amount: ${json['total_amount']}');
    print('   payment null? ${paymentRaw == null}');
    if (paymentRaw != null) {
      print('   payment.method: ${paymentRaw['method']}');
      print('   payment.is_cod: ${paymentRaw['is_cod']}');
      print('   payment.payment_status: ${paymentRaw['payment_status']}');
    }
    print('   items count: ${itemsRaw.length}');
    for (int i = 0; i < itemsRaw.length; i++) {
      final item = itemsRaw[i] as Map;
      print(
          '   item[$i] cod_charge: ${item['cod_charge']}  |  item_cod_share: ${item['item_cod_share']}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    // ══ END DEBUG ══════════════════════════════════════════════════════════
    return OrderModel(
      id: parseInt(json['id']),
      orderNumber: json['order_number'] ?? '',
      userId: parseInt(json['user']),
      sellerId: parseInt(json['seller']),
      status: json['status'] ?? 'pending',
      totalAmount: parseDouble(json['total_amount']),
      promoCode: json['promo_code'],
      subtotal: json['subtotal'] != null ? parseDouble(json['subtotal']) : null,
      discountAmount: json['discount_amount'] != null
          ? parseDouble(json['discount_amount'])
          : null,
      finalAmount: json['final_amount'] != null
          ? parseDouble(json['final_amount'])
          : null,
      discount: json['discount'] != null ? parseDouble(json['discount']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      canCancel: json['can_cancel'] ?? false,
      cancelWindowEndsAt: json['cancel_window_ends_at'] != null
          ? DateTime.parse(json['cancel_window_ends_at'])
          : null,
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      addresses: (json['addresses'] as List? ?? [])
          .map((e) => OrderAddress.fromJson(e))
          .toList(),
      shipping: json['shipping'] != null
          ? ShippingDetails.fromJson(json['shipping'])
          : null,
      payment: json['payment'] != null
          ? PaymentDetails.fromJson(json['payment'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user': userId,
      'seller': sellerId,
      'status': status,
      'total_amount': totalAmount,
      'promo_code': promoCode,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'discount': discount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'can_cancel': canCancel,
      'cancel_window_ends_at': cancelWindowEndsAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'addresses': addresses.map((address) => address.toJson()).toList(),
      'shipping': shipping?.toJson(),
      'payment': payment?.toJson(),
    };
  }

  // ── COD detection ────────────────────────────────────────────────────────────
  bool get isCODOrder {
    final byPayment = payment?.isCOD == true;
    final byItems = items.any((item) => (item.codCharge ?? 0.0) > 0);
    // ══ DEBUG ══
    print(
        '🔍 isCODOrder [$orderNumber]: payment.isCOD=$byPayment | itemsHaveCOD=$byItems | payment=${payment?.method} | itemCodCharges=${items.map((i) => i.codCharge).toList()}');
    // ══ END DEBUG ══
    if (byPayment) return true;
    if (byItems) return true;
    return false;
  }

  // ── COD charge ───────────────────────────────────────────────────────────────
  double get totalCodCharge {
    final fromItems = items.fold(
      0.0,
      (sum, item) => sum + (item.codCharge ?? 0.0),
    );
    // ══ DEBUG ══
    print(
        '💰 totalCodCharge [$orderNumber]: fromItems=$fromItems | feeAmount=${payment?.feeAmount}');
    // ══ END DEBUG ══
    if (fromItems > 0) return fromItems;
    if ((payment?.feeAmount ?? 0.0) > 0) return payment!.feeAmount!;
    return 0.0;
  }

  // ── Cancel helpers ───────────────────────────────────────────────────────────
  bool get canBeCancelled => canCancel && cancelWindowEndsAt != null;

  String get timeRemainingToCancel {
    if (!canCancel || cancelWindowEndsAt == null) return 'Cannot cancel';
    final diff = cancelWindowEndsAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Cannot cancel';
    if (diff.inHours >= 24) {
      final d = diff.inDays;
      return '$d day${d > 1 ? 's' : ''} left';
    } else if (diff.inHours >= 1) {
      final h = diff.inHours;
      return '$h hour${h > 1 ? 's' : ''} left';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} min left';
    }
    return 'Less than 1 min';
  }

  // ── Address helpers ──────────────────────────────────────────────────────────
  OrderAddress? get shippingAddress {
    try {
      return addresses
          .firstWhere((a) => a.addressType.toLowerCase() == 'shipping');
    } catch (_) {
      return null;
    }
  }

  OrderAddress? get billingAddress {
    try {
      return addresses
          .firstWhere((a) => a.addressType.toLowerCase() == 'billing');
    } catch (_) {
      return null;
    }
  }

  bool get isCompleted => status.toLowerCase() == 'delivered';
  bool get isActive =>
      !['cancelled', 'returned'].contains(status.toLowerCase());
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get formattedCreatedDate {
    final d = createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$minute';
  }

  String get formattedTotalAmount => '₹${totalAmount.toStringAsFixed(2)}';
  bool get hasTrackingInfo => shipping?.hasTrackingInfo == true;
}

// ─── OrderItem ────────────────────────────────────────────────────────────────

class OrderItem {
  final int id;
  final String productSlug;
  final String productId;
  final String name;
  final String? sku;
  final double price;
  final double? salePrice;
  final int quantity;
  final double finalPrice;
  final String status;

  final String? image;
  final double? regularPrice;
  final Map<String, String>? variantValues;

  final double? itemSubtotal;
  final double? itemDiscount;
  final double? itemFinalPrice;
  final double? discount;

  // ✅ cod_charge — per-item COD fee from API
  final double? codCharge;
  // ✅ item_cod_share — alias field the API also sends
  final double? itemCodShare;

  final double? deliveryCharges;
  final double? shippingCost;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;

  OrderItem({
    required this.id,
    required this.productSlug,
    required this.productId,
    required this.name,
    this.sku,
    required this.price,
    this.salePrice,
    required this.quantity,
    required this.finalPrice,
    required this.status,
    this.image,
    this.regularPrice,
    this.variantValues,
    this.itemSubtotal,
    this.itemDiscount,
    this.itemFinalPrice,
    this.discount,
    this.codCharge,
    this.itemCodShare,
    this.deliveryCharges,
    this.shippingCost,
    this.weight,
    this.length,
    this.width,
    this.height,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, String>? variantValues;
    if (json['variant_values'] is Map) {
      variantValues = Map<String, String>.from(
        (json['variant_values'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }

    // ✅ cod_charge: try 'cod_charge' first, fallback to 'item_cod_share'
    // API sends both: "cod_charge":50, "item_cod_share":50
    final rawCodCharge = json['cod_charge'] ?? json['item_cod_share'];

    // ══ DEBUG ══════════════════════════════════════════════════════════════
    print('   🛒 OrderItem.fromJson: ${json['name']}');
    print('      All keys: ${json.keys.toList()}');
    print(
        '      cod_charge raw: ${json['cod_charge']}  type: ${json['cod_charge']?.runtimeType}');
    print(
        '      item_cod_share raw: ${json['item_cod_share']}  type: ${json['item_cod_share']?.runtimeType}');
    print('      rawCodCharge resolved: $rawCodCharge');
    // ══ END DEBUG ══════════════════════════════════════════════════════════

    return OrderItem(
      id: parseInt(json['id']),
      productSlug: json['product_slug'] ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: json['name'] ?? 'Item',
      sku: json['sku'],
      // ✅ API does NOT send 'unit_price' — use sale_price → final_price → price
      price: parseDouble(
        json['sale_price'] ?? json['final_price'] ?? json['price'] ?? 0,
      ),
      salePrice:
          json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      regularPrice: json['regular_price'] != null
          ? parseDouble(json['regular_price'])
          : null,
      finalPrice: parseDouble(
        json['final_price'] ??
            json['item_final_price'] ??
            json['sale_price'] ??
            json['price'] ??
            0,
      ),
      quantity: parseInt(json['quantity']),
      status: json['status'] ?? 'pending',
      image: json['image'],
      variantValues: variantValues,
      itemSubtotal: json['item_subtotal'] != null
          ? parseDouble(json['item_subtotal'])
          : null,
      itemDiscount: json['item_discount'] != null
          ? parseDouble(json['item_discount'])
          : null,
      itemFinalPrice: json['item_final_price'] != null
          ? parseDouble(json['item_final_price'])
          : null,
      discount: json['discount'] != null ? parseDouble(json['discount']) : null,
      // ✅ Parse cod_charge with item_cod_share fallback
      codCharge: rawCodCharge != null ? parseDouble(rawCodCharge) : null,
      itemCodShare: json['item_cod_share'] != null
          ? parseDouble(json['item_cod_share'])
          : null,
      deliveryCharges: json['delivery_charges'] != null
          ? parseDouble(json['delivery_charges'])
          : null,
      shippingCost: json['shipping_cost'] != null
          ? parseDouble(json['shipping_cost'])
          : null,
      weight: json['weight'] != null ? parseDouble(json['weight']) : null,
      length: json['length'] != null ? parseDouble(json['length']) : null,
      width: json['width'] != null ? parseDouble(json['width']) : null,
      height: json['height'] != null ? parseDouble(json['height']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_slug': productSlug,
      'product_id': productId,
      'name': name,
      'sku': sku,
      'price': price,
      'sale_price': salePrice,
      'regular_price': regularPrice,
      'quantity': quantity,
      'final_price': finalPrice,
      'status': status,
      'image': image,
      'variant_values': variantValues,
      'cod_charge': codCharge,
      'item_cod_share': itemCodShare,
      'delivery_charges': deliveryCharges,
      'shipping_cost': shippingCost,
    };
  }

  double get effectivePrice => salePrice ?? price;
  double get mrp => regularPrice ?? price;
  bool get hasDiscount => mrp > effectivePrice;
  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((mrp - effectivePrice) / mrp) * 100).round();
  }

  double get totalValue => effectivePrice * quantity;
  String get formattedPrice => '₹${effectivePrice.round()}';
  String get formattedTotalValue => '₹${totalValue.round()}';
}

// ─── OrderAddress ─────────────────────────────────────────────────────────────

class OrderAddress {
  final int id;
  final int orderId;
  final String addressType;
  final String fullName;
  final String phone;
  final String email;
  final String street;
  final String area;
  final String? landmark;
  final String city;
  final String state;
  final String country;
  final String pincode;

  OrderAddress({
    required this.id,
    required this.orderId,
    required this.addressType,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.street,
    required this.area,
    this.landmark,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: parseInt(json['id']),
      orderId: parseInt(json['order']),
      addressType: json['address_type'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      landmark: json['landmark'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? 'India',
      pincode: json['pincode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': orderId,
        'address_type': addressType,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'street': street,
        'area': area,
        'landmark': landmark,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
      };

  String get fullAddress {
    final parts = <String>[
      street,
      if (area.isNotEmpty) area,
      if (landmark != null && landmark!.isNotEmpty) landmark!,
      city,
      state,
      country,
      pincode,
    ];
    return parts.join(', ');
  }

  String get shortAddress =>
      [street, if (area.isNotEmpty) area, city].join(', ');
}

// ─── ShippingDetails ──────────────────────────────────────────────────────────

class ShippingDetails {
  final int id;
  final int orderId;
  final String provider;
  final String? trackingId;
  final String? awbNumber;
  final String? trackingUrl;
  final String? courierName;
  final String? speed;
  final double weight;
  final double length;
  final double width;
  final double height;
  final String pickupLocation;
  final DateTime? pickupScheduled;
  final DateTime? expectedDelivery;
  final double? shippingCost;
  final String status;
  final List<dynamic> statusUpdates;
  final String? shipmojoOrderId;
  final String? shipmojoReferenceId;
  final String? courierCompanyId;
  final String? courierCompanyService;
  final String? warehouseId;
  final String? lrNumber;
  final String? labelUrl;
  final String? labelData;
  final String? pickupTokenNumber;
  final String? statusCode;
  final Map<String, dynamic> shipmojoResponse;
  final int? sellerId;
  final bool courierAssigned;
  final DateTime? courierAssignedAt;
  final bool pickupScheduledManually;
  final bool isReturnOrder;
  final int? returnReasonId;
  final String? returnReasonComment;
  final String? customerRequest;

  ShippingDetails({
    required this.id,
    required this.orderId,
    required this.provider,
    this.trackingId,
    this.awbNumber,
    this.trackingUrl,
    this.courierName,
    this.speed,
    required this.weight,
    required this.length,
    required this.width,
    required this.height,
    required this.pickupLocation,
    this.pickupScheduled,
    this.expectedDelivery,
    this.shippingCost,
    required this.status,
    required this.statusUpdates,
    this.shipmojoOrderId,
    this.shipmojoReferenceId,
    this.courierCompanyId,
    this.courierCompanyService,
    this.warehouseId,
    this.lrNumber,
    this.labelUrl,
    this.labelData,
    this.pickupTokenNumber,
    this.statusCode,
    required this.shipmojoResponse,
    this.sellerId,
    required this.courierAssigned,
    this.courierAssignedAt,
    required this.pickupScheduledManually,
    required this.isReturnOrder,
    this.returnReasonId,
    this.returnReasonComment,
    this.customerRequest,
  });

  factory ShippingDetails.fromJson(Map<String, dynamic> json) {
    return ShippingDetails(
      id: parseInt(json['id']),
      orderId: parseInt(json['order']),
      provider: json['provider'] ?? 'shipmojo',
      trackingId: json['tracking_id'],
      awbNumber: json['awb_number'],
      trackingUrl: json['tracking_url'],
      courierName: json['courier_name'],
      speed: json['speed'],
      weight: parseDouble(json['weight']),
      length: parseDouble(json['length']),
      width: parseDouble(json['width']),
      height: parseDouble(json['height']),
      pickupLocation: json['pickup_location'] ?? '',
      pickupScheduled: json['pickup_scheduled'] != null
          ? DateTime.tryParse(json['pickup_scheduled'])
          : null,
      expectedDelivery: json['expected_delivery'] != null
          ? DateTime.tryParse(json['expected_delivery'])
          : null,
      shippingCost: json['shipping_cost'] != null
          ? parseDouble(json['shipping_cost'])
          : null,
      status: json['status'] ?? '',
      statusUpdates:
          json['status_updates'] is List ? json['status_updates'] : [],
      shipmojoOrderId: json['shipmojo_order_id'],
      shipmojoReferenceId: json['shipmojo_reference_id'],
      courierCompanyId: json['courier_company_id'],
      courierCompanyService: json['courier_company_service'],
      warehouseId: json['warehouse_id'],
      lrNumber: json['lr_number'],
      labelUrl: json['label_url'],
      labelData: json['label_data'],
      pickupTokenNumber: json['pickup_token_number'],
      statusCode: json['status_code'],
      shipmojoResponse: json['shipmojo_response'] ?? {},
      sellerId: json['seller'] != null ? parseInt(json['seller']) : null,
      courierAssigned: json['courier_assigned'] ?? false,
      courierAssignedAt: json['courier_assigned_at'] != null
          ? DateTime.tryParse(json['courier_assigned_at'])
          : null,
      pickupScheduledManually: json['pickup_scheduled_manually'] ?? false,
      isReturnOrder: json['is_return_order'] ?? false,
      returnReasonId: json['return_reason_id'],
      returnReasonComment: json['return_reason_comment'],
      customerRequest: json['customer_request'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': orderId,
        'provider': provider,
        'tracking_id': trackingId,
        'awb_number': awbNumber,
        'tracking_url': trackingUrl,
        'courier_name': courierName,
        'speed': speed,
        'weight': weight,
        'length': length,
        'width': width,
        'height': height,
        'pickup_location': pickupLocation,
        'pickup_scheduled': pickupScheduled?.toIso8601String(),
        'expected_delivery': expectedDelivery?.toIso8601String(),
        'shipping_cost': shippingCost,
        'status': status,
        'status_updates': statusUpdates,
        'shipmojo_order_id': shipmojoOrderId,
        'courier_company_id': courierCompanyId,
        'courier_assigned': courierAssigned,
        'is_return_order': isReturnOrder,
      };

  bool get hasTrackingInfo => awbNumber != null && awbNumber!.isNotEmpty;
  bool get isShipped =>
      status.toLowerCase().contains('shipped') || courierAssigned;
  bool get isDelivered => status.toLowerCase().contains('delivered');
  bool get isCancelled => status.toLowerCase().contains('cancelled');

  String get displayStatus {
    if (isDelivered) return 'Delivered';
    if (isCancelled) return 'Cancelled';
    if (isShipped) return 'Shipped';
    if (courierAssigned) return 'Courier Assigned';
    if (shipmojoOrderId != null) return 'Processing';
    return 'Pending';
  }
}

// ─── PaymentDetails ───────────────────────────────────────────────────────────

class PaymentDetails {
  final int id;
  final int orderId;
  final String method;
  final String? methodDisplay;
  final String? transactionId;
  final String paymentStatus;
  final String? paymentStatusDisplay;
  // ✅ is_cod — direct boolean from API, more reliable than method string check
  final bool isCodFromApi;
  final double? amountPaid;
  final String? refundStatus;
  final double? refundAmount;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String? razorpayStatus;
  final String? paymentUrl;
  final String? callbackUrl;
  final String? redirectUrl;
  final Map<String, dynamic> razorpayResponse;
  final Map<String, dynamic> paymentMethodDetails;
  final double? feeAmount;
  final double? taxAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;

  PaymentDetails({
    required this.id,
    required this.orderId,
    required this.method,
    this.methodDisplay,
    this.transactionId,
    required this.paymentStatus,
    this.paymentStatusDisplay,
    required this.isCodFromApi,
    this.amountPaid,
    this.refundStatus,
    this.refundAmount,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.razorpayStatus,
    this.paymentUrl,
    this.callbackUrl,
    this.redirectUrl,
    required this.razorpayResponse,
    required this.paymentMethodDetails,
    this.feeAmount,
    this.taxAmount,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    // ══ DEBUG ══════════════════════════════════════════════════════════════
    print('   💳 PaymentDetails.fromJson keys: ${json.keys.toList()}');
    print('      method: ${json['method']}');
    print(
        '      is_cod: ${json['is_cod']}  type: ${json['is_cod']?.runtimeType}');
    print('      payment_status: ${json['payment_status']}');
    print('      amount_paid: ${json['amount_paid']}');
    // ══ END DEBUG ══════════════════════════════════════════════════════════
    return PaymentDetails(
      id: parseInt(json['id']),
      orderId: parseInt(json['order']),
      method: json['method'] ?? '',
      methodDisplay: json['method_display'],
      transactionId: json['transaction_id'],
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentStatusDisplay: json['payment_status_display'],
      // ✅ Read is_cod directly from API — most reliable
      isCodFromApi: json['is_cod'] == true,
      amountPaid:
          json['amount_paid'] != null ? parseDouble(json['amount_paid']) : null,
      refundStatus: json['refund_status'],
      refundAmount: json['refund_amount'] != null
          ? parseDouble(json['refund_amount'])
          : null,
      razorpayResponse: json['razorpay_response'] ?? {},
      paymentMethodDetails: json['payment_method_details'] ?? {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      paidAt:
          json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
      razorpayOrderId: json['razorpay_order_id'],
      razorpayPaymentId: json['razorpay_payment_id'],
      razorpaySignature: json['razorpay_signature'],
      razorpayStatus: json['razorpay_status'],
      paymentUrl: json['payment_url'],
      callbackUrl: json['callback_url'],
      redirectUrl: json['redirect_url'],
      feeAmount:
          json['fee_amount'] != null ? parseDouble(json['fee_amount']) : null,
      taxAmount:
          json['tax_amount'] != null ? parseDouble(json['tax_amount']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': orderId,
        'method': method,
        'method_display': methodDisplay,
        'transaction_id': transactionId,
        'payment_status': paymentStatus,
        'payment_status_display': paymentStatusDisplay,
        'is_cod': isCodFromApi,
        'amount_paid': amountPaid,
        'refund_status': refundStatus,
        'refund_amount': refundAmount,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'razorpay_status': razorpayStatus,
        'payment_url': paymentUrl,
        'callback_url': callbackUrl,
        'redirect_url': redirectUrl,
        'razorpay_response': razorpayResponse,
        'payment_method_details': paymentMethodDetails,
        'fee_amount': feeAmount,
        'tax_amount': taxAmount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
      };

  // ✅ isCOD: check API's is_cod field first, then method string
  bool get isCOD => isCodFromApi || method.toUpperCase() == 'COD';
  bool get isOnlinePayment => !isCOD;

  bool get isPaid =>
      paymentStatus.toLowerCase() == 'paid' ||
      paymentStatus.toLowerCase() == 'captured';
  bool get isPending => paymentStatus.toLowerCase() == 'pending';
  bool get isFailed => paymentStatus.toLowerCase() == 'failed';
  bool get isRefunded => paymentStatus.toLowerCase().contains('refund');

  String get displayStatus {
    if (paymentStatusDisplay != null && paymentStatusDisplay!.isNotEmpty) {
      return paymentStatusDisplay!;
    }
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
      case 'captured':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'partially_refunded':
        return 'Partially Refunded';
      case 'refund_initiated':
        return 'Refund Processing';
      default:
        return paymentStatus;
    }
  }
}
