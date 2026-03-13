// lib/presentation/pages/auth/login_page.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../api/services/auth_service.dart';
import '../../../providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:anu_app/config/theme.dart';
import '../../../providers/cart_provider.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import '../auth/forgot_password_page.dart';
import '../auth/otp_verification_page.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:anu_app/presentation/widgets/captcha_widget.dart'; // ✅

// ── Floating particle model ──
class _Particle {
  final IconData icon;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;
  final double rotationSpeed;

  _Particle({
    required this.icon,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
    required this.rotationSpeed,
  });
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _requiresVerification = false;
  String? _unverifiedEmail;

  // ✅ CAPTCHA state
  bool _showCaptcha = false;
  CaptchaValue? _captchaValue;
  String? _captchaError;
  int _captchaKey = 0; // increment to force CaptchaWidget rebuild (refresh)

  // ── Particle animation ──
  late AnimationController _particleController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _initParticles();
  }

  void _initParticles() {
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    final rng = math.Random();
    final icons = [
      Icons.lock_outline,
      Icons.person_outline,
      Icons.shopping_bag_outlined,
      Icons.star_outline,
      Icons.favorite_outline,
      Icons.local_offer_outlined,
    ];

    _particles = List.generate(18, (i) {
      return _Particle(
        icon: icons[i % icons.length],
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 12 + 16,
        speed: rng.nextDouble() * 0.2 + 0.08,
        delay: rng.nextDouble(),
        rotationSpeed:
            (rng.nextBool() ? 1 : -1) * (rng.nextDouble() * 0.8 + 0.2),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
        _requiresVerification = false;
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
        _requiresVerification = false;
      });
      return;
    }

    // ✅ If CAPTCHA is visible, enforce it before calling API
    if (_showCaptcha && _captchaValue == null) {
      setState(() => _captchaError = 'Please complete the security check.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _requiresVerification = false;
      _captchaError = null;
      _isLoading = true;
    });

    try {
      // ✅ Pass captchaId + captchaAnswer to AuthService if present
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
        captchaId: _captchaValue?.captchaId,
        captchaAnswer: _captchaValue?.captchaAnswer,
      );

      if (result['success']) {
        if (mounted) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.processLoginData(result['data']);

          final cartProvider =
              Provider.of<CartProvider>(context, listen: false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: LogoLoader()),
                  SizedBox(width: 12),
                  Text('Syncing your cart...'),
                ],
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFFFEAF4E),
            ),
          );

          await cartProvider.mergeGuestCartWithUserCart();
          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted) {
            final uri = GoRouterState.of(context).uri;
            final redirectUrl = uri.queryParameters['redirect'];
            final requireAuth = uri.queryParameters['requireAuth'];

            if (redirectUrl != null && redirectUrl.isNotEmpty) {
              final decodedUrl = Uri.decodeComponent(redirectUrl);
              context.push(decodedUrl);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  AppNotifications.showSuccess(context, 'Success message');
                }
              });
            } else {
              context.push('/home');
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  AppNotifications.showSuccess(context, 'Success message');
                }
              });
            }

            unawaited(
              Provider.of<WishlistProvider>(context, listen: false)
                  .initialize()
                  .catchError((e) {
                developer.log('Background wishlist init error: $e');
              }),
            );
          }
        }
      } else {
        if (result['requires_verification'] == true) {
          setState(() {
            _requiresVerification = true;
            _unverifiedEmail = result['email'] ?? _emailController.text.trim();
            _errorMessage = result['message'] ??
                'Your account is not verified. Please verify your email to continue.';
            _isLoading = false;
          });
        } else {
          // ✅ Backend says CAPTCHA required (5+ failed attempts)
          if (result['captcha_required'] == true) {
            setState(() {
              _showCaptcha = true;
              _captchaValue = null;
              _captchaKey++; // force CaptchaWidget to re-fetch image
              _captchaError =
                  result['error'] ?? 'Please complete the security check.';
            });
          }
          setState(() {
            _errorMessage = result['message'];
            _requiresVerification = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error in login: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _requiresVerification = false;
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToVerification() {
    if (_unverifiedEmail == null || _unverifiedEmail!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpVerificationPage(
          email: _unverifiedEmail!,
          fullName: '',
          isRegistration: false,
          onVerificationSuccess: (BuildContext context) async {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final userData = await _authService.getUserData();
            if (userData != null) {
              userProvider.setUserData(userData);
            }
            final cartProvider =
                Provider.of<CartProvider>(context, listen: false);
            await cartProvider.mergeGuestCartWithUserCart();
            if (mounted) {
              AppNotifications.showSuccess(context, 'Success message');
              context.go('/home');
            }
          },
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Widget _buildRedirectIndicator() {
    final uri = GoRouterState.of(context).uri;
    final redirectUrl = uri.queryParameters['redirect'];
    final requireAuth = uri.queryParameters['requireAuth'];

    if (redirectUrl != null && requireAuth == 'true') {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEAF4E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFEAF4E).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEAF4E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_cart,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Order',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Login to proceed with checkout',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Particle background ──
  Widget _buildParticleBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Stack(
              children: _particles.map((p) {
                final progress = (_particleController.value + p.delay) % 1.0;
                final yPos = (p.y + progress * p.speed * 3) % 1.0;
                final xWobble =
                    math.sin(progress * 2 * math.pi + p.delay * 10) * 0.03;
                final xPos = (p.x + xWobble).clamp(0.0, 1.0);
                final opacity =
                    (math.sin(progress * math.pi) * 0.22).clamp(0.04, 0.22);

                return Positioned(
                  left: size.width * xPos,
                  top: size.height * yPos,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: progress * 2 * math.pi * p.rotationSpeed,
                      child: Icon(
                        p.icon,
                        size: p.size,
                        color: const Color(0xFFF96A4C),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // ── Terms & Privacy footer ──
  Widget _buildTermsLine() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black45),
          children: [
            const TextSpan(text: 'By continuing, you agree to our '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => _launchUrl('https://anugami.com/terms'),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: const Text(
                    'Terms',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      decorationColor: Color(0xFFF96A4C),
                    ),
                  ),
                ),
              ),
            ),
            const TextSpan(text: ' & '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => _launchUrl('https://anugami.com/privacy-policy'),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                      decorationColor: Color(0xFFF96A4C),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Stack(
          children: [
            // 🌈 Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF96A4C).withOpacity(0.06),
                    const Color(0xFFFFF8F5),
                    const Color(0xFFFEAF4E).withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // ✨ Particle background
            _buildParticleBackground(),

            // 📋 Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with gradient
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login to your account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Welcome back to our store',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        // Login form
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRedirectIndicator(),

                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: _requiresVerification
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _requiresVerification
                                            ? Colors.orange.shade200
                                            : Colors.red.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _requiresVerification
                                                ? Icons.warning_amber_rounded
                                                : Icons.error_outline,
                                            color: _requiresVerification
                                                ? Colors.orange.shade800
                                                : Colors.red.shade800,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: _requiresVerification
                                                    ? Colors.orange.shade800
                                                    : Colors.red.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_requiresVerification) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _navigateToVerification,
                                            icon: const Icon(
                                                Icons.verified_user,
                                                size: 18),
                                            label: const Text(
                                                'Verify Account Now'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFEAF4E),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                              // Email field
                              const Text(
                                'Email',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'your@email.com',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF96A4C)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              const Text(
                                'Password',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFF96A4C)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        AppTheme.primaryGradient.createShader(
                                      Rect.fromLTWH(
                                          0, 0, bounds.width, bounds.height),
                                    ),
                                    child: const Text(
                                      'Forgot your password?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ✅ CAPTCHA — shown after 5 failed login attempts
                              if (_showCaptcha) ...[
                                const SizedBox(height: 8),
                                CaptchaWidget(
                                  key: ValueKey(_captchaKey),
                                  onVerify: (val) {
                                    setState(() {
                                      _captchaValue = val;
                                      if (val != null) _captchaError = null;
                                    });
                                  },
                                  externalError: _captchaError,
                                ),
                                const SizedBox(height: 8),
                              ],

                              const SizedBox(height: 16),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (_isLoading ||
                                          (_showCaptcha &&
                                              _captchaValue == null))
                                      ? null
                                      : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: (_isLoading ||
                                              (_showCaptcha &&
                                                  _captchaValue == null))
                                          ? null
                                          : AppTheme.primaryGradient,
                                      color: (_isLoading ||
                                              (_showCaptcha &&
                                                  _captchaValue == null))
                                          ? Colors.grey
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isLoading)
                                            const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: LogoLoader())
                                          else
                                            const Icon(Icons.login_rounded),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isLoading
                                                ? 'Logging in...'
                                                : 'Login',
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Create account link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Flexible(
                                    child: Text(
                                      "Don't have an account?",
                                      style: TextStyle(color: Colors.black54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/create-account'),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          AppTheme.primaryGradient.createShader(
                                        Rect.fromLTWH(
                                            0, 0, bounds.width, bounds.height),
                                      ),
                                      child: const Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ✅ Terms & Privacy line
                              _buildTermsLine(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
