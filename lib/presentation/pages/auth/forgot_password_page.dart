// lib/presentation/pages/auth/forgot_password_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';
import '../../../api/services/auth_service.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _floatingIconsController;
  late AnimationController _gradientController;
  late AnimationController _formController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  List<FloatingIcon> _floatingIcons = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateFloatingIcons();
  }

  void _initializeAnimations() {
    _floatingIconsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOut,
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutBack,
    ));

    _formController.forward();
  }

  void _generateFloatingIcons() {
    final icons = [
      Icons.shopping_bag_outlined,
      Icons.local_shipping_outlined,
      Icons.lock_outlined,
      Icons.favorite_outline,
      Icons.star_outline,
      Icons.shopping_cart_outlined,
      Icons.shield_outlined,
      Icons.card_giftcard_outlined,
    ];

    final colors = [
      const Color(0xFFf97316),
      const Color(0xFF0ea5e9),
      const Color(0xFF8b5cf6),
      const Color(0xFFec4899),
      const Color(0xFFeab308),
      const Color(0xFF10b981),
      const Color(0xFF6366f1),
      const Color(0xFFf43f5e),
    ];

    _floatingIcons = List.generate(12, (index) {
      return FloatingIcon(
        icon: icons[index % icons.length],
        color: colors[index % colors.length],
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: math.Random().nextDouble() * 8 + 16,
        speed: math.Random().nextDouble() * 0.3 + 0.2,
        delay: math.Random().nextDouble() * 2,
      );
    });
  }

  @override
  void dispose() {
    _floatingIconsController.dispose();
    _gradientController.dispose();
    _formController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email is invalid';
    }
    return null;
  }

  // ✅ Now calls OTP-based reset and navigates to OTP step
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final result = await _authService.requestPasswordResetOTP(email);

      if (!mounted) return;

      if (result['success']) {
        HapticFeedback.lightImpact();
        // ✅ Navigate to reset_password_page, pass email + start from OTP step
        context.push('/reset-password', extra: email);
      } else {
        setState(() {
          _errorMessage = result['message'];
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error occurred. Please try again.';
      });
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 64 : 24,
                    vertical: 32,
                  ),
                  child: SlideTransition(
                    position: _formSlideAnimation,
                    child: FadeTransition(
                      opacity: _formFadeAnimation,
                      child: _buildFormCard(isTablet),
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

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned(
                  top: -100 + (_gradientController.value * 50),
                  right: -100 + (_gradientController.value * 30),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.primaryColor.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingIconsController,
          builder: (context, child) {
            return Stack(
              children: _floatingIcons.map((floatingIcon) {
                final progress =
                    (_floatingIconsController.value + floatingIcon.delay) % 1.0;
                final y = floatingIcon.y +
                    (progress * floatingIcon.speed * 2) -
                    floatingIcon.speed;

                return Positioned(
                  left: MediaQuery.of(context).size.width * floatingIcon.x,
                  top: MediaQuery.of(context).size.height * (y % 1.0),
                  child: Opacity(
                    opacity: 0.4,
                    child: Transform.rotate(
                      angle: progress * 2 * math.pi,
                      child: Icon(
                        floatingIcon.icon,
                        color: floatingIcon.color,
                        size: floatingIcon.size,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isTablet) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 480 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: PatternPainter()),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/icon1.png',
                      width: 500,
                      height: 500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form content
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 170, 32, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email. We\'ll send a 6-digit OTP to reset your password.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Error alert
                  if (_errorMessage != null) ...[
                    _buildAlert(message: _errorMessage!, isError: true),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: 'Email Address '),
                        TextSpan(
                            text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline,
                          color: AppTheme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppTheme.primaryColor, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Send OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    width: 20, height: 20, child: LogoLoader()),
                                const SizedBox(width: 12),
                                const Text(
                                  'Sending OTP...',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Send OTP',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Back to login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(
                          'Login',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert({required String message, required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isError ? Colors.red[200]! : Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red[600] : Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? Colors.red[800] : Colors.green[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Supporting classes (unchanged)
// ─────────────────────────────────────────────
class FloatingIcon {
  final IconData icon;
  final Color color;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

  FloatingIcon({
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1);
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        canvas.drawCircle(
            Offset((size.width / 10) * i, (size.height / 10) * j), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
