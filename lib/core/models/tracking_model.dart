class TrackingModel {
  final String orderNumber;
  final String status;
  final TrackingShippingDetails? shippingDetails;
  final List<TrackingUpdateModel> statusHistory;

  TrackingModel({
    required this.orderNumber,
    required this.status,
    this.shippingDetails,
    required this.statusHistory,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? '',
      shippingDetails: json['shipping_details'] != null
          ? TrackingShippingDetails.fromJson(json['shipping_details'])
          : null,
      statusHistory:
          (json['shipping_details']?['status_history'] as List<dynamic>?)
                  ?.map((update) => TrackingUpdateModel.fromJson(update))
                  .toList() ??
              [],
    );
  }
}

class TrackingUpdateModel {
  final String status;
  final DateTime date;
  final String? location;
  final String? activity;

  TrackingUpdateModel({
    required this.status,
    required this.date,
    this.location,
    this.activity,
  });

  factory TrackingUpdateModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['date']);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return TrackingUpdateModel(
      status: json['status'] ?? '',
      date: parsedDate,
      location: json['location'],
      activity: json['activity'],
    );
  }
}

class TrackingShippingDetails {
  final String provider;
  final String? trackingId;
  final String? awbCode;
  final String? courierName;
  final String? trackingUrl;
  final String status;
  final DateTime? pickupDate;
  final String? labelUrl;
  final String? manifestUrl;

  TrackingShippingDetails({
    required this.provider,
    this.trackingId,
    this.awbCode,
    this.courierName,
    this.trackingUrl,
    required this.status,
    this.pickupDate,
    this.labelUrl,
    this.manifestUrl,
  });

  factory TrackingShippingDetails.fromJson(Map<String, dynamic> json) {
    DateTime? parsedPickupDate;
    if (json['pickup_date'] != null) {
      try {
        parsedPickupDate = DateTime.parse(json['pickup_date']);
      } catch (e) {
        parsedPickupDate = null;
      }
    }

    return TrackingShippingDetails(
      provider: json['provider'] ?? 'Unknown',
      trackingId: json['tracking_id'],
      awbCode: json['awb_code'] ?? json['awb_number'],
      courierName: json['courier'] ?? json['courier_name'],
      trackingUrl: json['tracking_url'],
      status: json['status'] ?? '',
      pickupDate: parsedPickupDate,
      labelUrl: json['label_url'],
      manifestUrl: json['manifest_url'],
    );
  }
}
