// lib/presentation/pages/profile/profile_page.dart
import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'dart:developer' as developer;
import '../../../api/services/auth_service.dart';
import '../../../api/services/profile_service.dart';
import '../../../core/models/profile_model.dart';
import '../../../providers/user_provider.dart';
import '../shared/custom_bottom_nav.dart';
import 'package:anu_app/utils/app_notifications.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  ProfileModel? _profileData;
  String? _error;
  bool _isAuthError = false; // ✅ track if error is auth-related

  static const Color _brandColor = Color(0xFFF96A4C);

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) context.go('/login');
      return;
    }
    _loadProfile();
  }

  /// Returns true if the error message indicates an auth/token issue
  bool _checkIsAuthError(String? msg) {
    if (msg == null) return false;
    final lower = msg.toLowerCase();
    return lower.contains('token') ||
        lower.contains('unauthorized') ||
        lower.contains('authentication') ||
        lower.contains('not authenticated') ||
        lower.contains('invalid') ||
        lower.contains('expired') ||
        lower.contains('login') ||
        lower.contains('401') ||
        lower.contains('403');
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isAuthError = false;
    });

    try {
      final result = await _profileService.getUserProfile();

      if (result['success']) {
        final profile = ProfileModel.fromJson(result['data']);
        setState(() {
          _profileData = profile;
          _isLoading = false;
        });
      } else {
        final msg = result['message'] as String?;
        final isAuth = _checkIsAuthError(msg);

        if (isAuth && mounted) {
          // ✅ Stale token — clear and go to login immediately
          final authService = AuthService();
          await authService.logout();
          if (mounted) context.go('/login');
          return;
        }

        setState(() {
          _error = msg;
          _isAuthError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      final msg = 'Failed to load profile data: $e';
      final isAuth = _checkIsAuthError(msg);

      if (isAuth && mounted) {
        final authService = AuthService();
        await authService.logout();
        if (mounted) context.go('/login');
        return;
      }

      setState(() {
        _error = msg;
        _isAuthError = false;
        _isLoading = false;
      });
    }
  }

  void _navigateToEditProfile() async {
    if (_profileData == null) return;
    final result =
        await context.push<bool>('/profile/edit', extra: _profileData);
    if (result == true) _loadProfile();
  }

  String _getDisplayName() {
    if (_profileData == null) return 'User';
    try {
      final dynamic data = _profileData;
      if ((data as dynamic).fullName != null &&
          (data as dynamic).fullName.toString().isNotEmpty) {
        return (data as dynamic).fullName.toString();
      }
    } catch (_) {}
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _brandColor,
                    _brandColor.withOpacity(0.5),
                    _brandColor.withOpacity(0.25),
                    _brandColor.withOpacity(0.12),
                    _brandColor.withOpacity(0.05),
                  ],
                  stops: const [0.0, 0.15, 0.3, 0.6, 0.8],
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadProfile,
            child: _buildBody(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: LogoLoader());
    }

    // ✅ Auth error — show session expired + login button
    if (_error != null && _isAuthError) {
      return _buildSessionExpiredView();
    }

    // Generic error
    if (_error != null) {
      return _buildGenericErrorView();
    }

    if (_profileData == null) {
      return const Center(
        child: Text('No profile data available',
            style: TextStyle(color: Colors.white)),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildQuickActionButtons(),
              const SizedBox(height: 24),
              _buildMenuSection(),
              const SizedBox(height: 24),
              _buildActivitySection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Session expired view
  Widget _buildSessionExpiredView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_outlined,
                  size: 52, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Expired',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              'Your session has expired. Please login again to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login, size: 20),
                label: const Text('Login Again',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _brandColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generic (non-auth) error view
  Widget _buildGenericErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          const Text('Error Loading Profile',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9))),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: _brandColor),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/loader1.png',
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 40),
                    ),
                    const SizedBox(width: 12),
                    const Text('Anugami',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'GoodTimes')),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications,
                          color: Colors.black, size: 20),
                      onPressed: () =>
                          context.push('/notification-preferences'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search,
                          color: Colors.black, size: 20),
                      onPressed: () => context.push('/search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.black.withOpacity(0.1),
                    child: _profileData?.profilePicture != null &&
                            _profileData!.profilePicture!.isNotEmpty
                        ? Image.network(
                            _profileData!.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person,
                                    size: 50, color: Colors.black54),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.black54),
                                ),
                              );
                            },
                          )
                        : const Icon(Icons.person,
                            size: 50, color: Colors.black54),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(
                          text: 'Hello, ',
                          style: TextStyle(color: Colors.black, fontSize: 22)),
                      TextSpan(
                          text: _getDisplayName(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildActionButton(
                      'Your order', () => context.push('/orders'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton(
                      'Wishlist', () => context.push('/wishlist'))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildActionButton(
                      'Coupons', () => context.push('/coupons'))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildActionButton('Edit Profile', () {
                if (_profileData != null) _navigateToEditProfile();
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black)),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMenuItem(Icons.credit_card, 'Saved Cards & Wallet', () {}),
          const SizedBox(height: 6),
          _buildMenuItem(Icons.location_on_outlined, 'Saved Addresses',
              () => context.push('/profile/addresses')),
          const SizedBox(height: 6),
          _buildMenuItem(Icons.notifications_outlined, 'Notifications Settings',
              () => context.push('/notification-preferences')),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('My Activity',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildMenuItem(
                  Icons.edit_outlined, 'Edit Profile', _navigateToEditProfile),
              const SizedBox(height: 6),
              _buildMenuItem(Icons.history, 'Order History',
                  () => context.push('/orders')),
              const SizedBox(height: 6),
              _buildMenuItem(Icons.security_outlined, 'Password & Security',
                  () => context.push('/forgot-password')),
              const SizedBox(height: 6),
              _buildMenuItem(Icons.help_outline, 'Contact Us',
                  () => context.push('/contact')),
              const SizedBox(height: 6),
              _buildMenuItem(Icons.logout, 'Logout', _showLogoutDialog,
                  iconColor: Colors.red,
                  titleColor: Colors.red,
                  showChevron: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {Color? iconColor, Color? titleColor, bool showChevron = true}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.black, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? Colors.black)),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
                color: _brandColor, borderRadius: BorderRadius.circular(8)),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        decoration: BoxDecoration(color: _brandColor),
        child: const Center(child: LogoLoader()),
      ),
    );

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/login');
      AppNotifications.showSuccess(context, 'Success message');
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        AppNotifications.showError(context, 'Error message');
      }
    }
  }
}
