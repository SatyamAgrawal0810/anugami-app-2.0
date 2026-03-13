// lib/providers/address_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../api/services/address_service.dart';
import '../core/models/address_model.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _error;

  // Form controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();

  // Form state
  String _selectedAddressType = 'home';
  bool _isDefault = false;
  bool _isFormLoading = false;

  // Getters
  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedAddressType => _selectedAddressType;
  bool get isDefault => _isDefault;
  bool get isFormLoading => _isFormLoading;

  // Get default address if exists
  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  // Form setters
  void setAddressType(String type) {
    _selectedAddressType = type;
    notifyListeners();
  }

  void setIsDefault(bool value) {
    _isDefault = value;
    notifyListeners();
  }

  // Load all addresses
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.getAddresses();

      if (result['success']) {
        _addresses = List<AddressModel>.from(result['data']);
        _isLoading = false;
        notifyListeners();
      } else {
        _error = result['message'];
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create address from form controllers
  AddressModel createAddressFromForm() {
    return AddressModel(
      addressType: _selectedAddressType,
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim(),
      street: streetController.text.trim(),
      city: cityController.text.trim(),
      state: stateController.text.trim(),
      country: 'India',
      pincode: pincodeController.text.trim(),
      landmark: landmarkController.text.trim(),
      isDefault: _isDefault,
    );
  }

  // Populate form for editing
  void populateFormForEdit(AddressModel address) {
    fullNameController.text = address.fullName;
    phoneController.text = address.phone;
    streetController.text = address.street;
    cityController.text = address.city;
    stateController.text = address.state;
    pincodeController.text = address.pincode;
    landmarkController.text = address.landmark ?? '';
    _selectedAddressType = address.addressType;
    _isDefault = address.isDefault;
    notifyListeners();
  }

  // Clear form controllers
  void clearForm() {
    fullNameController.clear();
    phoneController.clear();
    streetController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();
    landmarkController.clear();
    _selectedAddressType = 'home';
    _isDefault = false;
    notifyListeners();
  }

  // Validate form
  Map<String, String?> validateForm() {
    Map<String, String?> errors = {};

    if (fullNameController.text.trim().isEmpty) {
      errors['fullName'] = 'Full name is required';
    } else if (fullNameController.text.trim().length < 2) {
      errors['fullName'] = 'Full name must be at least 2 characters';
    }

    if (phoneController.text.trim().isEmpty) {
      errors['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneController.text.trim())) {
      errors['phone'] = 'Please enter a valid 10-digit phone number';
    }

    if (streetController.text.trim().isEmpty) {
      errors['street'] = 'Street address is required';
    }

    if (cityController.text.trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    if (stateController.text.trim().isEmpty) {
      errors['state'] = 'State is required';
    }

    if (pincodeController.text.trim().isEmpty) {
      errors['pincode'] = 'Pincode is required';
    } else if (!RegExp(r'^\d{6}$').hasMatch(pincodeController.text.trim())) {
      errors['pincode'] = 'Please enter a valid 6-digit pincode';
    }

    // Landmark is optional, but if provided, check length
    if (landmarkController.text.trim().isNotEmpty &&
        landmarkController.text.trim().length > 50) {
      errors['landmark'] = 'Landmark must be less than 50 characters';
    }

    return errors;
  }

  // Add new address using form
  Future<Map<String, dynamic>> addAddressFromForm() async {
    // Validate form first
    final validationErrors = validateForm();
    if (validationErrors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Please fix the form errors',
        'errors': validationErrors
      };
    }

    _isFormLoading = true;
    _error = null;
    notifyListeners();

    try {
      final address = createAddressFromForm();
      final result = await _addressService.addAddress(address.toJson());

      _isFormLoading = false;

      if (result['success']) {
        // Clear form on success
        clearForm();
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isFormLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add new address
  Future<Map<String, dynamic>> addAddress(AddressModel address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.addAddress(address.toJson());

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update address using form
  Future<Map<String, dynamic>> updateAddressFromForm(String id) async {
    // Validate form first
    final validationErrors = validateForm();
    if (validationErrors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Please fix the form errors',
        'errors': validationErrors
      };
    }

    _isFormLoading = true;
    _error = null;
    notifyListeners();

    try {
      final address = createAddressFromForm();
      final result = await _addressService.updateAddress(id, address.toJson());

      _isFormLoading = false;

      if (result['success']) {
        // Clear form on success
        clearForm();
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isFormLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update address
  Future<Map<String, dynamic>> updateAddress(
      String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.updateAddress(id, data);

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Set address as default
  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Find the address to update
      final address = _addresses.firstWhere((addr) => addr.id == id);

      // Create a copy with is_default set to true
      final updatedAddress = address.copyWith(isDefault: true);

      // Use the existing updateAddress method since it works
      final result =
          await _addressService.updateAddress(id, updatedAddress.toJson());

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete address
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _addressService.deleteAddress(id);

      _isLoading = false;

      if (result['success']) {
        // Reload addresses to get updated list
        await loadAddresses();
        return {'success': true};
      } else {
        _error = result['message'];
        notifyListeners();
        return {
          'success': false,
          'message': result['message'],
          'errors': result['errors']
        };
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose all controllers
    fullNameController.dispose();
    phoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    landmarkController.dispose();
    super.dispose();
  }
}
