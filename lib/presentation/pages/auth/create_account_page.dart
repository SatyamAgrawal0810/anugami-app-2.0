// lib/presentation/pages/auth/create_account_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../api/services/auth_service.dart';
import '../../../providers/user_provider.dart';
import 'otp_verification_page.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

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

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  DateTime? _selectedDate;
  String _selectedGender = 'Male';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ── Password strength ──
  int _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

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
      duration: const Duration(seconds: 22),
    )..repeat();

    final rng = math.Random();
    final icons = [
      Icons.person_add_outlined,
      Icons.shopping_bag_outlined,
      Icons.star_outline,
      Icons.favorite_outline,
      Icons.local_offer_outlined,
      Icons.card_giftcard_outlined,
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String value) {
    int score = 0;
    if (value.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthLabel = '';
      });
      return;
    }
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) score++;

    setState(() {
      if (score <= 1) {
        _passwordStrength = 1;
        _passwordStrengthLabel = 'Weak';
      } else if (score == 2 || score == 3) {
        _passwordStrength = 2;
        _passwordStrengthLabel = 'Medium';
      } else {
        _passwordStrength = 3;
        _passwordStrengthLabel = 'Strong';
      }
    });
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF96A4C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fieldErrors = null;
    });

    final userData = {
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'password': _passwordController.text,
      'confirm_password': _confirmPasswordController.text,
    };

    if (_selectedDate != null) {
      userData['date_of_birth'] =
          DateFormat('yyyy-MM-dd').format(_selectedDate!);
    }
    if (_selectedGender.isNotEmpty) {
      userData['gender'] = _selectedGender.toLowerCase();
    }

    try {
      developer
          .log('Starting registration process with email OTP verification');
      final result = await _authService.register(userData);
      setState(() => _isLoading = false);

      if (!result['success']) {
        _handleRegistrationError(result);
        return;
      }

      developer.log('Registration successful, navigating to OTP verification');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              email: result['email'] ?? _emailController.text.trim(),
              fullName: _fullNameController.text.trim(),
              isRegistration: true,
              onVerificationSuccess: (BuildContext context) async {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final userData = await _authService.getUserData();
                if (userData != null) userProvider.setUserData(userData);
                if (mounted) {
                  AppNotifications.showSuccess(context, 'Success message');
                  context.push('/home');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Error in registration process: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void _handleRegistrationError(Map<String, dynamic> result) {
    if (result['errors'] != null && result['errors'] is Map) {
      setState(() => _fieldErrors = result['errors']);
      if (result['message'] != null) {
        setState(() => _errorMessage = result['message']);
      }
    } else if (result['message'] != null) {
      setState(() => _errorMessage = result['message']);
    } else {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
    }
    if (mounted) AppNotifications.showError(context, 'Error message');
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
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create your account',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Join our community and start shopping',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ✅ Close button — top right
                                GestureDetector(
                                  onTap: () => context.go('/home'),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Form
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Error message
                                if (_errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            color: Colors.red.shade800,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                                color: Colors.red.shade800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Full Name
                                _buildFormLabel('Full Name', true),
                                _buildTextField(
                                  controller: _fullNameController,
                                  hintText: 'Enter your full name',
                                  fieldName: 'full_name',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Name must be at least 2 characters long';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Email
                                _buildFormLabel('Email', true),
                                _buildTextField(
                                  controller: _emailController,
                                  hintText: 'your@email.com',
                                  fieldName: 'email',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Phone
                                _buildFormLabel('Phone', true),
                                _buildTextField(
                                  controller: _phoneController,
                                  hintText: 'Enter your phone number',
                                  fieldName: 'phone',
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    final cleanPhone =
                                        value.replaceAll(RegExp(r'[^\d]'), '');
                                    if (cleanPhone.length < 10) {
                                      return 'Please enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // DOB + Gender row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildFormLabel(
                                              'Date of Birth', false),
                                          InkWell(
                                            onTap: () => _selectDate(context),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade300),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _selectedDate == null
                                                          ? 'dd-mm-yyyy'
                                                          : DateFormat(
                                                                  'dd-MM-yyyy')
                                                              .format(
                                                                  _selectedDate!),
                                                      style: TextStyle(
                                                        color: _selectedDate ==
                                                                null
                                                            ? Colors
                                                                .grey.shade500
                                                            : Colors.black,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                      Icons.calendar_today,
                                                      size: 18),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildFormLabel('Gender', false),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: _selectedGender,
                                                isExpanded: true,
                                                icon: const Icon(
                                                    Icons.arrow_drop_down),
                                                items: _genderOptions
                                                    .map((String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                onChanged: (newValue) {
                                                  setState(() =>
                                                      _selectedGender =
                                                          newValue!);
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Password with strength indicator
                                _buildFormLabel('Password', true),
                                _buildTextField(
                                  controller: _passwordController,
                                  hintText: 'Create a password',
                                  fieldName: 'password',
                                  obscureText: _obscurePassword,
                                  onChanged: _updatePasswordStrength,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),

                                if (_passwordStrength > 0) ...[
                                  const SizedBox(height: 8),
                                  _buildPasswordStrengthBar(),
                                ],

                                const SizedBox(height: 16),

                                // Confirm Password
                                _buildFormLabel('Confirm Password', true),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  hintText: 'Confirm your password',
                                  fieldName: 'confirm_password',
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscureConfirmPassword =
                                          !_obscureConfirmPassword);
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Info box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "We'll send a verification code to your email address to complete registration.",
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Create Account button
                                ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleRegistration,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.white,
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: _isLoading
                                          ? null
                                          : AppTheme.primaryGradient,
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
                                              child: LogoLoader(),
                                            )
                                          : const Text(
                                              'Create Account',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account?',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/login'),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => AppTheme
                                            .primaryGradient
                                            .createShader(
                                          Rect.fromLTWH(0, 0, bounds.width,
                                              bounds.height),
                                        ),
                                        child: const Text(
                                          'Log in',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final filled = index < _passwordStrength;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  color: filled ? _strengthColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey(_passwordStrengthLabel),
            children: [
              Icon(
                _passwordStrength == 1
                    ? Icons.sentiment_dissatisfied_outlined
                    : _passwordStrength == 2
                        ? Icons.sentiment_neutral_outlined
                        : Icons.sentiment_satisfied_outlined,
                size: 14,
                color: _strengthColor,
              ),
              const SizedBox(width: 4),
              Text(
                _passwordStrengthLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _strengthColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _passwordStrength == 1
                    ? '— Use uppercase, numbers & symbols'
                    : _passwordStrength == 2
                        ? '— Add a symbol to make it stronger'
                        : '— Great password!',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String fieldName,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    String? fieldError;
    if (_fieldErrors != null && _fieldErrors!.containsKey(fieldName)) {
      if (_fieldErrors![fieldName] is List) {
        fieldError = (_fieldErrors![fieldName] as List).first.toString();
      } else if (_fieldErrors![fieldName] is String) {
        fieldError = _fieldErrors![fieldName];
      }
    }

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
        suffixIcon: suffixIcon,
        errorText: fieldError,
      ),
      validator: validator,
    );
  }
}