// lib/presentation/pages/profile/my_addresses_page.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/address_model.dart';
import '../../../providers/address_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/address_card.dart';
import '../auth/address_form_page.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';

class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({Key? key}) : super(key: key);

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    // Use the address provider to load addresses
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    await addressProvider.loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Addresses',
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAddresses,
        child: Consumer<AddressProvider>(
          builder: (context, addressProvider, child) {
            if (addressProvider.isLoading) {
              return const Center(
                child: const LogoLoader(),
              );
            }

            if (addressProvider.error != null) {
              return _buildErrorView(addressProvider.error!);
            }

            if (addressProvider.addresses.isEmpty) {
              return _buildEmptyAddressView();
            }

            return _buildAddressList(addressProvider.addresses);
          },
        ),
      ),
      bottomNavigationBar:
          const CustomBottomNavBar(currentIndex: 4), // Profile tab
      floatingActionButton: InkWell(
        onTap: () => _navigateToAddAddress(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load addresses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _loadAddresses,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddressView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No Addresses Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Add a new address to have your orders delivered',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              InkWell(
                onTap: () => _navigateToAddAddress(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add New Address',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(List<AddressModel> addresses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return AddressCard(
          address: address,
          onEdit: () => _navigateToEditAddress(address),
          onDelete: () => _confirmDeleteAddress(address),
          onSetDefault:
              address.isDefault ? null : () => _setDefaultAddress(address.id!),
        );
      },
    );
  }

  void _navigateToAddAddress() {
    context.push('/address-form?mode=newAddress');
  }

  void _navigateToEditAddress(AddressModel address) {
    context.push('/address-form?mode=editAddress');
  }

  Future<void> _setDefaultAddress(String addressId) async {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);

    // Show loading indicator
    _showLoadingDialog('Setting as default...');

    final result = await addressProvider.setDefaultAddress(addressId);

    // Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    if (!result['success']) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? 'Failed to set as default address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show success message
      if (mounted) {
        AppNotifications.showSuccess(context, 'Success message');
      }
    }
  }

  Future<void> _confirmDeleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text(
          'Are you sure you want to delete this address? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAddress(address.id!);
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);

    // Show loading indicator
    _showLoadingDialog('Deleting address...');

    final result = await addressProvider.deleteAddress(addressId);

    // Dismiss loading dialog
    if (mounted) Navigator.pop(context);

    if (!result['success']) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show success message
      if (mounted) {
        AppNotifications.showSuccess(context, 'Success message');
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const LogoLoader(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }
}
