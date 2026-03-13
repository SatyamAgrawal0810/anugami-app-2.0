// lib/presentation/pages/auth/address_form_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../api/services/auth_service.dart';
import '../../../api/services/address_service.dart';
import '../../../core/models/address_model.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/address_provider.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

enum AddressFormMode {
  registration, // For user registration flow
  newAddress, // For adding a new address from My Addresses
  editAddress, // For editing an existing address
}

class AddressFormPage extends StatefulWidget {
  final String? fullName;
  final String? phone;
  final AddressFormMode mode;
  final AddressModel? address; // For edit mode

  const AddressFormPage({
    Key? key,
    this.fullName,
    this.phone,
    this.mode = AddressFormMode.registration,
    this.address,
  }) : super(key: key);

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _addressService = AddressService();

  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');
  final _pincodeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _landmarkController = TextEditingController();

  String _selectedAddressType = 'home';
  bool _isDefault = true;
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _addressTypes = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.mode == AddressFormMode.editAddress && widget.address != null) {
      // Edit mode - populate with existing address data
      final address = widget.address!;
      _fullNameController.text = address.fullName;
      _phoneController.text = address.phone;
      _streetController.text = address.street;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _countryController.text = address.country;
      _pincodeController.text = address.pincode;
      _landmarkController.text = address.landmark ?? '';
      _selectedAddressType = address.addressType;
      _isDefault = address.isDefault;
    } else if (widget.mode == AddressFormMode.registration) {
      // Registration mode - use provided name and phone
      _fullNameController.text = widget.fullName ?? '';
      _phoneController.text = widget.phone ?? '';
    } else {
      // New address mode - try to get user data from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isLoggedIn) {
        _fullNameController.text = userProvider.fullName;
        if (userProvider.userData != null &&
            userProvider.userData!.containsKey('phone')) {
          _phoneController.text = userProvider.userData!['phone'];
        }
      }
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final addressData = AddressModel(
      id: widget.mode == AddressFormMode.editAddress
          ? widget.address!.id
          : null,
      addressType: _selectedAddressType,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim(),
      pincode: _pincodeController.text.trim(),
      landmark: _landmarkController.text.trim(),
      isDefault: _isDefault,
    );

    try {
      Map<String, dynamic> result;

      if (widget.mode == AddressFormMode.registration) {
        // Use AuthService for registration flow
        result = await _authService.addAddress(addressData.toJson());
      } else {
        // Use AddressProvider for adding/updating address
        final addressProvider =
            Provider.of<AddressProvider>(context, listen: false);

        if (widget.mode == AddressFormMode.newAddress) {
          result = await addressProvider.addAddress(addressData);
        } else {
          result = await addressProvider.updateAddress(
              addressData.id!, addressData.toJson());
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Show success message
        if (mounted) {
          AppNotifications.showSuccess(context, 'Success message');

          // Navigate based on mode
          if (widget.mode == AddressFormMode.registration) {
            context.push('/home');
          } else {
            context.pop();
          }
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to save address';

          // Handle validation errors from server
          if (result['errors'] != null && result['errors'] is Map) {
            final errors = result['errors'] as Map<String, dynamic>;
            final errorMessages = errors.values
                .where((error) => error is String)
                .map((error) => error.toString())
                .toList();

            if (errorMessages.isNotEmpty) {
              _errorMessage = errorMessages.join('\n');
            }
          }
        });
      }
    } catch (e) {
      developer.log('AddressFormPage: Error saving address: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  String _getSuccessMessage() {
    switch (widget.mode) {
      case AddressFormMode.registration:
        return 'Address added successfully';
      case AddressFormMode.newAddress:
        return 'Address added successfully';
      case AddressFormMode.editAddress:
        return 'Address updated successfully';
    }
  }

  String _getPageTitle() {
    switch (widget.mode) {
      case AddressFormMode.registration:
        return 'Add Delivery Address';
      case AddressFormMode.newAddress:
        return 'Add New Address';
      case AddressFormMode.editAddress:
        return 'Edit Address';
    }
  }

  // Validation methods
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    } else if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your pincode';
    } else if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  String? _validateLandmark(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a landmark';
    } else if (value.trim().length > 50) {
      return 'Landmark must be less than 50 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: Text(
          _getPageTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFEAF4E),
                Color(0xFFF96A4C),
                Color(0xFFE54481),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _getPageTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Personal details section
                      if (widget.mode != AddressFormMode.registration) ...[
                        _buildFormLabel('Full Name', true),
                        _buildTextField(
                          controller: _fullNameController,
                          hintText: 'Enter your full name',
                          validator: _validateFullName,
                        ),
                        const SizedBox(height: 16),
                        _buildFormLabel('Phone Number', true),
                        _buildTextField(
                          controller: _phoneController,
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Full Name: ${widget.fullName}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Phone: ${widget.phone}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Address type selection
                      _buildFormLabel('Address Type', false),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAddressType,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _addressTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value.toUpperCase(),
                                  style: const TextStyle(
                                    textBaseline: TextBaseline.alphabetic,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedAddressType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Street Address
                      _buildFormLabel('Street Address', true),
                      _buildTextField(
                        controller: _streetController,
                        hintText: 'House/Flat number, Building, Street',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your street address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // City
                      _buildFormLabel('City', true),
                      _buildTextField(
                        controller: _cityController,
                        hintText: 'Enter your city',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // State and Pincode
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('State', true),
                                _buildTextField(
                                  controller: _stateController,
                                  hintText: 'Enter state',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormLabel('Pincode', true),
                                _buildTextField(
                                  controller: _pincodeController,
                                  hintText: 'Enter pincode',
                                  keyboardType: TextInputType.number,
                                  validator: _validatePincode,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Country
                      _buildFormLabel('Country', true),
                      _buildTextField(
                        controller: _countryController,
                        hintText: 'Enter your country',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Landmark (required)
                      _buildFormLabel('Landmark', true),
                      _buildTextField(
                        controller: _landmarkController,
                        hintText:
                            'Enter nearby landmark for easy identification',
                        maxLines: 2,
                        validator: _validateLandmark,
                      ),

                      const SizedBox(height: 16),

                      // Set as default address
                      Row(
                        children: [
                          Checkbox(
                            value: _isDefault,
                            activeColor: const Color(
                                0xFFF96A4C), // Middle color of gradient
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Set as default address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Display error message if any
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAddress,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFFEAF4E),
                                      Color(0xFFF96A4C),
                                      Color(0xFFE54481),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            color: _isLoading ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(
                              minWidth: double.infinity,
                              minHeight: 50,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: const LogoLoader(),
                                  )
                                : Text(
                                    widget.mode == AddressFormMode.editAddress
                                        ? 'Update Address'
                                        : 'Save Address',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),

                      // Skip button for registration only
                      if (widget.mode == AddressFormMode.registration) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed:
                              _isLoading ? null : () => context.push('/home'),
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                AppTheme.primaryGradient.createShader(
                              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                            ),
                            child: const Text(
                              'Skip for now',
                              style: TextStyle(
                                color: Colors
                                    .white, // This will be masked by gradient
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF96A4C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }
}
