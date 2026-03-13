// lib/core/models/address_model.dart
class AddressModel {
  final String? id;
  final String addressType;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String landmark;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.addressType,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.landmark,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString(),
      addressType: json['address_type'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'address_type': addressType,
      'full_name': fullName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'landmark': landmark,
      'is_default': isDefault,
    };

    // Don't include id in the request unless it exists
    if (id != null) {
      map['id'] = id as Object;
    }

    return map;
  }

  // Create a copy with modified fields
  AddressModel copyWith({
    String? id,
    String? addressType,
    String? fullName,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? country,
    String? pincode,
    String? landmark,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      addressType: addressType ?? this.addressType,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
