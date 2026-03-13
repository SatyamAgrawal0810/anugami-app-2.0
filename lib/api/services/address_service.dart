// lib/api/services/address_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/address_model.dart';

class AddressService {
  final String baseUrl = 'https://anugami.com/api/v1';

  // Get all addresses for the customer
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/customers/addresses/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Successfully retrieved addresses
        List<AddressModel> addresses = [];
        if (responseData is List) {
          addresses = responseData
              .map((addressJson) => AddressModel.fromJson(addressJson))
              .toList();
        }

        return {
          'success': true,
          'data': addresses,
        };
      } else {
        // Failed to get addresses
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch addresses',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Add a new address
  Future<Map<String, dynamic>> addAddress(
      Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      // Make sure phone is included
      if (!addressData.containsKey('phone') || addressData['phone'].isEmpty) {
        // Try to get it from user data
        final userData = await _getUserData();
        if (userData != null && userData.containsKey('phone')) {
          addressData['phone'] = userData['phone'];
        } else {
          addressData['phone'] = ''; // Empty default
        }
      }

      // Add country if missing
      if (!addressData.containsKey('country') ||
          addressData['country'].isEmpty) {
        addressData['country'] = 'India'; // Default country
      }

      final response = await http.post(
        Uri.parse('$baseUrl/customers/addresses/add/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(addressData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Address added successfully
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Failed to add address
        print('Address creation failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add address',
          'errors': responseData,
        };
      }
    } catch (e) {
      print('Exception in addAddress: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Update an existing address
  Future<Map<String, dynamic>> updateAddress(
      String addressId, Map<String, dynamic> addressData) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/customers/addresses/$addressId/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(addressData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Address updated successfully
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        // Failed to update address
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update address',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Set an address as default

  // Delete an address
  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/customers/addresses/$addressId/delete/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 204) {
        // Address deleted successfully (No content)
        return {
          'success': true,
        };
      } else {
        // Failed to delete address
        Map<String, dynamic> responseData = {};
        try {
          if (response.body.isNotEmpty) {
            responseData = json.decode(response.body);
          }
        } catch (_) {}

        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete address',
          'errors': responseData,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // Get saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Get saved user data
  Future<Map<String, dynamic>?> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }
}
