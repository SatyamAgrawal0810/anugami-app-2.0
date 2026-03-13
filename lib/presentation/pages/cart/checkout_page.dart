// lib/presentation/pages/cart/checkout_page.dart
// ✅ COMPLETE FINAL CHECKOUT - All Features + Auto Address Save
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../api/services/order_service.dart';
import '../../../api/services/cart_image_service.dart';
import '../../../core/models/address_model.dart';
import 'package:anu_app/config/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../api/services/auth_service.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:anu_app/utils/app_notifications.dart';

class CheckoutPage extends StatefulWidget {
  // Buy Now parameters
  final String? buyNowProductId;
  final String? buyNowProductName;
  final String? buyNowPrice;
  final String? buyNowRegularPrice;
  final String? buyNowImage;
  final String? buyNowVariantId;
  final String? buyNowColor;
  final String? buyNowSize;

  const CheckoutPage({
    Key? key,
    this.buyNowProductId,
    this.buyNowProductName,
    this.buyNowPrice,
    this.buyNowRegularPrice,
    this.buyNowImage,
    this.buyNowVariantId,
    this.buyNowColor,
    this.buyNowSize,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final CartImageService _cartImageService = CartImageService();
  late Razorpay _razorpay;

  // State management
  int _currentStep = 0;
  bool _isLoading = false;
  bool _processingPayment = false;
  bool _checkingAddress = true;
  AddressModel? _selectedAddress;
  bool _useExistingAddress = false;

  // Cart images state
  Map<int, String?> _cartItemImages = {};
  bool _loadingCartImages = false;

  bool get isBuyNowMode => widget.buyNowProductId != null;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  // Payment & Coupon
  String _paymentMethod = 'Razorpay-UPI';
  List<Map<String, dynamic>> _availableCoupons = [];
  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  bool _loadingCoupons = false;

  // ✅ Extra charges from API
  double _shippingCharge = 0.0;
  double _codCharge = 0.0;
  bool _freeShippingApplied = false;
  String? _chargeConfigName;
  bool _loadingCharges = false;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadAddresses();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    if (!isLoggedIn && mounted) {
      context.push('/login?redirect=/checkout');
    }
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _loadAddresses() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addressProvider =
          Provider.of<AddressProvider>(context, listen: false);
      await addressProvider.loadAddresses();

      if (addressProvider.addresses.isNotEmpty) {
        final defaultAddr =
            addressProvider.defaultAddress ?? addressProvider.addresses.first;

        setState(() {
          _selectedAddress = defaultAddr;
          _useExistingAddress = true;
          _currentStep = 1;
          _checkingAddress = false;
        });
        _populateFormFromAddress(defaultAddr);
        _loadAvailableCoupons();
        _loadCartImages();

        double subtotal = _calculateSubtotal();
        _fetchExtraCharges(subtotal);
      } else {
        setState(() => _checkingAddress = false);
      }
    });
  }

  void _populateFormFromAddress(AddressModel address) {
    _nameController.text = address.fullName;
    _phoneController.text = address.phone;
    _streetController.text = address.street;
    // 'N/A' placeholder ko form mein empty dikhao
    _landmarkController.text = address.landmark;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _pincodeController.text = address.pincode;
  }

  double _calculateSubtotal() {
    if (isBuyNowMode) {
      return double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
    } else {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      return cartProvider.subtotal;
    }
  }

  // ✅ AUTO-SAVE NEW ADDRESS
  // Yeh method tab call hoga jab user naya address fill karke "Continue to Review" click kare
  // Agar user ne existing address select kiya hai to save nahi hoga
  Future<void> _saveNewAddressIfNeeded() async {
    // Agar existing address selected hai to kuch nahi karna
    if (_useExistingAddress && _selectedAddress != null) return;

    try {
      final addressProvider =
          Provider.of<AddressProvider>(context, listen: false);

      // Landmark empty ho to empty string nahi, space ya kuch dalo
      // API blank accept nahi karta, isliye default value dete hai

      final newAddress = AddressModel(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        landmark: _landmarkController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: 'India',
        pincode: _pincodeController.text.trim(),
        addressType: 'home',
        // Agar pehla address hai to default bana do
        isDefault: addressProvider.addresses.isEmpty,
      );

      print('💾 Saving new address for: ${newAddress.fullName}');

      final result = await addressProvider.addAddress(newAddress);

      if (result['success'] == true) {
        print('✅ Address saved successfully!');

        // Naya saved address ko select karo
        if (mounted && addressProvider.addresses.isNotEmpty) {
          setState(() {
            _selectedAddress = addressProvider.addresses.last;
            _useExistingAddress = true;
          });
        }
      } else {
        print('⚠️ Address save failed: ${result['message']}');
        // Silent fail - checkout continue karta rahega
      }
    } catch (e) {
      print('⚠️ Address save error: $e');
      // Silent fail - checkout continue karta rahega
    }
  }

  // ✅ Load cart item images
  Future<void> _loadCartImages() async {
    if (isBuyNowMode) return;

    setState(() => _loadingCartImages = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = cartProvider.items;

    for (var item in items) {
      if (item.productInfo?.slug != null) {
        final imageUrl = await _cartImageService.getCartItemImageUrl(
          item.productInfo!.slug,
          item.variantId,
        );

        if (mounted) {
          setState(() {
            _cartItemImages[item.id] = imageUrl;
          });
        }
      }
    }

    if (mounted) {
      setState(() => _loadingCartImages = false);
    }
  }

  Future<void> _loadAvailableCoupons() async {
    setState(() => _loadingCoupons = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      double orderTotal;
      if (isBuyNowMode) {
        orderTotal = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
      } else {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        orderTotal = cartProvider.subtotal;
      }

      final uri =
          Uri.parse('https://anugami.com/api/v1/offers/available/').replace(
        queryParameters: {'order_total': orderTotal.toString()},
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coupons = List<Map<String, dynamic>>.from(data['coupons'] ?? []);

        setState(() {
          _availableCoupons = coupons;
          _loadingCoupons = false;
        });
      }
    } catch (e) {
      print('🎟️ Error loading coupons: $e');
      setState(() => _loadingCoupons = false);
    }
  }

  Future<void> _applyCoupon(String code) async {
    final coupon = _availableCoupons.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {},
    );

    if (coupon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon not found'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (coupon['is_applicable'] != true) {
      final minCart = coupon['min_cart_value'] ?? 0;
      double orderTotal;
      if (isBuyNowMode) {
        orderTotal = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
      } else {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        orderTotal = cartProvider.subtotal;
      }

      if (minCart > orderTotal) {
        AppNotifications.showError(
            context, 'Minimum cart value: ₹${minCart.round()}');
      } else {
        AppNotifications.showError(context, 'Coupon not applicable');
      }
      return;
    }

    double discount =
        double.tryParse(coupon['calculated_discount'].toString()) ?? 0.0;

    if (discount == 0) {
      final discountType = coupon['discount_type'] ?? 'percent';
      final discountValue =
          double.tryParse(coupon['discount_value'].toString()) ?? 0.0;
      final maxDiscount = coupon['max_discount'];

      double orderTotal;
      if (isBuyNowMode) {
        orderTotal = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
      } else {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        orderTotal = cartProvider.subtotal;
      }

      if (discountType == 'percent') {
        discount = (orderTotal * discountValue) / 100;
      } else {
        discount = discountValue;
      }

      if (maxDiscount != null) {
        final maxDiscountValue = double.tryParse(maxDiscount.toString()) ?? 0.0;
        if (maxDiscountValue > 0 && discount > maxDiscountValue) {
          discount = maxDiscountValue;
        }
      }
    }

    if (discount == 0) {
      AppNotifications.showError(context, 'Coupon discount is zero');
      return;
    }

    setState(() {
      _appliedCouponCode = code;
      _couponDiscount = discount;
    });

    AppNotifications.showSuccess(
        context, 'Coupon applied! You saved ₹${discount.round()}');
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponDiscount = 0.0;
      _couponController.clear();
    });
  }

  Future<void> _fetchExtraCharges(double orderTotal) async {
    setState(() => _loadingCharges = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse(
            'https://anugami.com/api/v1/extra_charges/extra-charges/preview/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'order_total': orderTotal.toStringAsFixed(2),
          'payment_method': _paymentMethod,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _shippingCharge =
              double.tryParse(data['shipping_charge'].toString()) ?? 0.0;
          _codCharge = double.tryParse(data['cod_charge'].toString()) ?? 0.0;
          _freeShippingApplied = data['free_shipping_applied'] ?? false;
          _chargeConfigName = data['config_name'];
          _loadingCharges = false;
        });
      } else {
        setState(() {
          _shippingCharge = 0.0;
          _codCharge = 0.0;
          _freeShippingApplied = false;
          _chargeConfigName = null;
          _loadingCharges = false;
        });
      }
    } catch (e) {
      print('Error fetching extra charges: $e');
      setState(() {
        _shippingCharge = 0.0;
        _codCharge = 0.0;
        _loadingCharges = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _couponController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) return;

    setState(() => _processingPayment = true);

    try {
      final verificationResult = await _orderService.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (!mounted) return;

      if (verificationResult['success']) {
        _showSuccessDialog('Payment successful!');
      } else {
        _showError('Payment verification failed');
      }
    } catch (e) {
      if (mounted) _showError('Payment error: $e');
    } finally {
      if (mounted) setState(() => _processingPayment = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showError('Payment failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showError('External wallet not supported');
  }

  // ✅ FIXED _nextStep - naya address automatically save hoga
  void _nextStep() async {
    if (_currentStep == 0) {
      // ✅ Existing address selected hai to form validate skip karo, seedha next step
      if (_useExistingAddress && _selectedAddress != null) {
        setState(() => _currentStep = 1);
        _loadAvailableCoupons();
        _loadCartImages();
        double subtotal = _calculateSubtotal();
        _fetchExtraCharges(subtotal);
        return;
      }

      // Naya address dala hai to pehle validate karo
      if (!_formKey.currentState!.validate()) return;

      // ✅ Naya address save karo
      await _saveNewAddressIfNeeded();

      setState(() => _currentStep = 1);
      _loadAvailableCoupons();
      _loadCartImages();

      double subtotal = _calculateSubtotal();
      _fetchExtraCharges(subtotal);
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);

      double subtotal = _calculateSubtotal();
      _fetchExtraCharges(subtotal);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _placeOrder() async {
    if (_currentStep != 2) return;

    setState(() => _isLoading = true);

    try {
      final shippingAddress = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'street': _streetController.text.trim(),
        'area': _areaController.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': 'India',
        'pincode': _pincodeController.text.trim(),
        'use_for_billing': true,
      };

      final checkoutResult = await _orderService.checkout(
        shippingAddress: shippingAddress,
        paymentMethod: _paymentMethod,
        couponCode: _appliedCouponCode,
        clearCart: !isBuyNowMode && _paymentMethod == 'COD',
        autoCreateShipments: _paymentMethod == 'COD',
      );

      if (!mounted) return;

      if (checkoutResult['success']) {
        final data = checkoutResult['data'];

        if (data['payment_required'] == true) {
          final razorpayData = data['razorpay_data'];
          _startRazorpayPayment(razorpayData);
        } else {
          _showSuccessDialog('Order placed successfully!');
        }
      } else {
        _showError(checkoutResult['message'] ?? 'Checkout failed');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startRazorpayPayment(Map<String, dynamic> razorpayData) {
    setState(() => _processingPayment = true);

    var options = {
      'key': razorpayData['key_id'],
      'amount': razorpayData['amount'],
      'currency': razorpayData['currency'],
      'name': 'Anugami Store',
      'order_id': razorpayData['order_id'],
      'prefill': {
        'contact': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
      },
    };

    _razorpay.open(options);
  }

  void _showError(String message) {
    if (!mounted) return;
    AppNotifications.showError(context, message);
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;

    final scaffoldContext =
        context; // ✅ dialog open hone se pehle context save karo

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text(
          'Order Placed Successfully!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          // ✅ View Orders
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // dialog band
                if (!isBuyNowMode) {
                  Provider.of<CartProvider>(scaffoldContext, listen: false)
                      .clearCart();
                }
                scaffoldContext.go('/orders'); // ✅ saved context use karo
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('View Orders'),
            ),
          ),
          const SizedBox(height: 8),
          // ✅ Continue Shopping
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // dialog band
                if (!isBuyNowMode) {
                  Provider.of<CartProvider>(scaffoldContext, listen: false)
                      .clearCart();
                }
                scaffoldContext.go('/home'); // ✅ home pe jaao
              },
              child: Text(
                'Continue Shopping',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isBuyNowMode ? 'Buy Now - Checkout' : 'Checkout',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _currentStep > 0 ? _previousStep : () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (!_checkingAddress) _buildStepIndicator(),
          Expanded(
            child: _checkingAddress
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        LogoLoader(),
                        SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _isLoading || _processingPayment
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const LogoLoader(),
                            const SizedBox(height: 16),
                            Text(
                              _processingPayment
                                  ? 'Processing Payment...'
                                  : 'Creating Order...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildCurrentStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepCircle(0, 'Address'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Review'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Payment'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  isActive || isCompleted ? AppTheme.primaryGradient : null,
              color: isActive || isCompleted ? null : Colors.grey.shade300,
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryColor
                    : isCompleted
                        ? Colors.green
                        : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive || isCompleted
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? AppTheme.primaryColor
                  : isCompleted
                      ? Colors.green
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: isCompleted ? AppTheme.primaryGradient : null,
          color: isCompleted ? null : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildReviewStep();
      case 2:
        return _buildPaymentStep();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: ADDRESS
  Widget _buildAddressStep() {
    return Consumer<AddressProvider>(
      builder: (context, addressProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (addressProvider.addresses.isNotEmpty) ...[
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...addressProvider.addresses.map((address) {
                    final isSelected = _selectedAddress?.id == address.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAddress = address;
                          _useExistingAddress = true;
                        });
                        _populateFormFromAddress(address);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${address.street}, ${address.city}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const Divider(height: 32),
                  // ✅ "Add New Address" heading - jab user naya address dalna chahta hai
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _useExistingAddress = false;
                        _selectedAddress = null;
                      });
                      // Form clear karo naya address ke liye
                      _nameController.clear();
                      _phoneController.clear();
                      _emailController.clear();
                      _streetController.clear();
                      _areaController.clear();
                      _landmarkController.clear();
                      _cityController.clear();
                      _stateController.clear();
                      _pincodeController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: !_useExistingAddress
                            ? AppTheme.primaryColor.withOpacity(0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_useExistingAddress
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: !_useExistingAddress ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_location_alt_outlined,
                            color: !_useExistingAddress
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Address',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_useExistingAddress
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  const Text(
                    'Enter Delivery Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
                // ✅ Form sirf tab dikhao jab naya address dalna ho ya koi saved address nahi hai
                if (!_useExistingAddress ||
                    addressProvider.addresses.isEmpty) ...[
                  _buildAddressForm(),
                  const SizedBox(height: 24),
                ],
                _buildNextButton(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'Enter your name' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'Enter phone number' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'Enter email address' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          decoration: const InputDecoration(
            labelText: 'Street Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.home_outlined),
          ),
          maxLines: 2,
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'Enter street address' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _areaController,
          decoration: const InputDecoration(
            labelText: 'Area/Locality *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          validator: (v) =>
              v?.trim().isEmpty ?? true ? 'Enter area/locality' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _landmarkController,
          decoration: const InputDecoration(
            labelText: 'Landmark *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (v) => v?.trim().isEmpty ?? true ? 'Enter city' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stateController,
          decoration: const InputDecoration(
            labelText: 'State *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.map_outlined),
          ),
          validator: (v) => v?.trim().isEmpty ?? true ? 'Enter state' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_drop_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          validator: (v) =>
              v?.trim().length != 6 ? 'Enter valid 6-digit pincode' : null,
        ),
      ],
    );
  }

  // STEP 2: REVIEW
  Widget _buildReviewStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        double subtotal;
        double originalTotal = 0.0;
        double productDiscount = 0.0;

        if (isBuyNowMode) {
          subtotal = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
          final regularPrice = double.tryParse(
                  widget.buyNowRegularPrice ?? widget.buyNowPrice ?? '0') ??
              0.0;
          originalTotal = regularPrice;
          productDiscount = originalTotal - subtotal;
        } else {
          subtotal = cartProvider.subtotal;
          for (var item in cartProvider.items) {
            originalTotal += item.regularPrice * item.quantity;
          }
          productDiscount = originalTotal - subtotal;
        }

        final shipping = _shippingCharge;
        final couponDiscount = _couponDiscount;
        final codFee = _paymentMethod == 'COD' ? _codCharge : 0.0;
        final total = subtotal + shipping - couponDiscount + codFee;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectedAddressCard(),
              const SizedBox(height: 16),
              const Text(
                'Order Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (isBuyNowMode)
                _buildBuyNowProductCard()
              else
                ...cartProvider.items.map((item) => _buildProductCard(item)),
              const SizedBox(height: 16),
              _buildCouponSection(),
              const SizedBox(height: 16),
              _buildOrderSummary(
                originalTotal,
                productDiscount,
                subtotal,
                shipping,
                couponDiscount,
                codFee,
                total,
              ),
              const SizedBox(height: 24),
              _buildNextButton(),
              const SizedBox(height: 16),
              _buildTermsText(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Deliver to:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _nameController.text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${_streetController.text}, ${_cityController.text}, ${_stateController.text} - ${_pincodeController.text}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Phone: ${_phoneController.text}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyNowProductCard() {
    final price = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
    final regularPrice = double.tryParse(
            widget.buyNowRegularPrice ?? widget.buyNowPrice ?? '0') ??
        0.0;
    final hasDiscount = regularPrice > price;
    final discountPercent = hasDiscount
        ? (((regularPrice - price) / regularPrice) * 100).round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade100,
                child:
                    widget.buyNowImage != null && widget.buyNowImage!.isNotEmpty
                        ? Image.network(
                            widget.buyNowImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Colors.grey.shade400,
                          ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.buyNowProductName ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (widget.buyNowColor != null || widget.buyNowSize != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (widget.buyNowColor != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'Color: ${widget.buyNowColor}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (widget.buyNowSize != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'Size: ${widget.buyNowSize}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (hasDiscount) ...[
                    Row(
                      children: [
                        Text(
                          '₹${regularPrice.round()}',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      '₹${price.round()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Qty: 1',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(item) {
    String imageUrl = '';
    if (_cartItemImages.containsKey(item.id) &&
        _cartItemImages[item.id] != null) {
      imageUrl = _cartItemImages[item.id]!;
    } else if (item.productInfo?.image != null &&
        item.productInfo!.image.isNotEmpty) {
      imageUrl = item.productInfo!.image;
    }

    final hasDiscount = item.regularPrice > item.salePrice;
    final discountPercent = hasDiscount
        ? (((item.regularPrice - item.salePrice) / item.regularPrice) * 100)
            .round()
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade100,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      String? variantColor;
                      String? variantSize;

                      try {
                        if (item.variant != null && item.variant is Map) {
                          variantColor = item.variant['color']?.toString();
                          variantSize = item.variant['size']?.toString();
                        }
                      } catch (e) {}

                      try {
                        if (variantColor == null && variantSize == null) {
                          if (item.variantDetails != null &&
                              item.variantDetails is Map) {
                            variantColor =
                                item.variantDetails['color']?.toString();
                            variantSize =
                                item.variantDetails['size']?.toString();
                          }
                        }
                      } catch (e) {}

                      try {
                        if (variantColor == null && variantSize == null) {
                          if (item.selectedVariant != null &&
                              item.selectedVariant is Map) {
                            variantColor =
                                item.selectedVariant['color']?.toString();
                            variantSize =
                                item.selectedVariant['size']?.toString();
                          }
                        }
                      } catch (e) {}

                      if (variantColor != null || variantSize != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (variantColor != null &&
                                  variantColor.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.purple.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Color: $variantColor',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              if (variantSize != null && variantSize.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Size: $variantSize',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  if (hasDiscount) ...[
                    Row(
                      children: [
                        Text(
                          '₹${item.regularPrice.round()}',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$discountPercent% OFF',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppTheme.primaryGradient.createShader(bounds),
                    child: Text(
                      '₹${item.salePrice.round()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apply Coupon',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/coupons'),
                  icon: const Icon(Icons.local_offer, size: 16),
                  label: const Text('View All'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_appliedCouponCode != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedCouponCode!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'You saved ₹${_couponDiscount.round()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: _removeCoupon,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_couponController.text.isNotEmpty) {
                        _applyCoupon(_couponController.text);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              if (_availableCoupons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Available Coupons (${_availableCoupons.length > 2 ? "2+" : _availableCoupons.length})',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...(_availableCoupons.take(2).map((coupon) {
                  return GestureDetector(
                    onTap: () => _applyCoupon(coupon['code']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  coupon['code'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${coupon['discount_value']}% off',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })).toList(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    double originalTotal,
    double productDiscount,
    double subtotal,
    double shipping,
    double couponDiscount,
    double codFee,
    double total,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (productDiscount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Original Price',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    '₹${originalTotal.round()}',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildSummaryRow('Product Discount', -productDiscount,
                  isDiscount: true),
              const Divider(height: 16),
            ],
            _buildSummaryRow('Subtotal', subtotal),
            if (shipping > 0) _buildSummaryRow('Shipping', shipping),
            if (_freeShippingApplied)
              _buildSummaryRow('Shipping', 0, isFreeShipping: true),
            if (couponDiscount > 0) ...[
              _buildSummaryRow('Coupon Discount', -couponDiscount,
                  isDiscount: true),
              if (_appliedCouponCode != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    '($_appliedCouponCode)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
            if (codFee > 0)
              _buildSummaryRow('COD Handling Fee', codFee, isCOD: true),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${total.round()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isDiscount = false,
      bool isCOD = false,
      bool isFreeShipping = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            isFreeShipping
                ? 'FREE'
                : isDiscount
                    ? '- ₹${amount.abs().round()}'
                    : '₹${amount.abs().round()}',
            style: TextStyle(
              fontSize: 14,
              color: isDiscount || isFreeShipping
                  ? Colors.green
                  : isCOD
                      ? Colors.red
                      : Colors.black87,
              fontWeight: isDiscount || isCOD || isFreeShipping
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: PAYMENT
  Widget _buildPaymentStep() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        double subtotal;
        double originalTotal = 0.0;
        double productDiscount = 0.0;

        if (isBuyNowMode) {
          subtotal = double.tryParse(widget.buyNowPrice ?? '0') ?? 0.0;
          final regularPrice = double.tryParse(
                  widget.buyNowRegularPrice ?? widget.buyNowPrice ?? '0') ??
              0.0;
          originalTotal = regularPrice;
          productDiscount = originalTotal - subtotal;
        } else {
          subtotal = cartProvider.subtotal;
          for (var item in cartProvider.items) {
            originalTotal += item.regularPrice * item.quantity;
          }
          productDiscount = originalTotal - subtotal;
        }

        final shipping = _shippingCharge;
        final couponDiscount = _couponDiscount;
        final codFee = _paymentMethod == 'COD' ? _codCharge : 0.0;
        final total = subtotal + shipping - couponDiscount + codFee;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFFFFF8E1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Online Payment Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _paymentMethod = 'Razorpay-UPI');
                          _fetchExtraCharges(subtotal);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'Razorpay-UPI'
                                ? const Color.fromARGB(255, 253, 229, 200)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'Razorpay-UPI'
                                  ? const Color(0xFFF96A4C)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: _paymentMethod == 'Razorpay-UPI'
                                    ? const Color(0xFFF96A4C)
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Online Payment',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _paymentMethod == 'Razorpay-UPI'
                                            ? const Color(0xFFF96A4C)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'UPI, Cards, Net Banking, Wallets',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'No extra charges',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _paymentMethod == 'Razorpay-UPI'
                                      ? const Color(0xFFF96A4C)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _paymentMethod == 'Razorpay-UPI'
                                        ? const Color(0xFFF96A4C)
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _paymentMethod == 'Razorpay-UPI'
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // COD Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _paymentMethod = 'COD');
                          _fetchExtraCharges(subtotal);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _paymentMethod == 'COD'
                                ? Colors.orange.shade50
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == 'COD'
                                  ? const Color(0xFFF96A4C)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.money,
                                color: _paymentMethod == 'COD'
                                    ? const Color(0xFFF96A4C)
                                    : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cash on Delivery',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _paymentMethod == 'COD'
                                            ? const Color(0xFFF96A4C)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Pay when you receive',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '+₹50 COD handling charge',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _paymentMethod == 'COD'
                                      ? const Color(0xFFF96A4C)
                                      : Colors.white,
                                  border: Border.all(
                                    color: _paymentMethod == 'COD'
                                        ? const Color(0xFFF96A4C)
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _paymentMethod == 'COD'
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildOrderSummary(
                originalTotal,
                productDiscount,
                subtotal,
                shipping,
                couponDiscount,
                codFee,
                total,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    child: Text(
                      _paymentMethod == 'COD'
                          ? 'Place Order (₹${total.round()})'
                          : 'Pay ₹${total.round()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTermsText(),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          child: Text(
            _currentStep == 0 ? 'Continue to Review' : 'Proceed to Payment',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'By completing this purchase, you acknowledge and agree to Anugami\'s ',
            style: TextStyle(fontSize: 11, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          GestureDetector(
            onTap: () async {
              const url = 'https://anugami.com/terms';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ' & ',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          GestureDetector(
            onTap: () async {
              const url = 'https://anugami.com/privacy-policy';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.none,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
