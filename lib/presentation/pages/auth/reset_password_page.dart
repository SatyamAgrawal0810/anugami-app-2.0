// lib/presentation/pages/auth/reset_password_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../api/services/auth_service.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

// ─────────────────────────────────────────────
//  Enum for the 3 steps
// ─────────────────────────────────────────────
enum ResetStep { email, otp, newPassword }

class ResetPasswordPage extends StatefulWidget {
  /// When navigated from ForgotPasswordPage, email is passed via GoRouter extra.
  /// This skips the email step and jumps directly to OTP entry.
  final String? initialEmail;

  const ResetPasswordPage({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();

  // ── Current step ──
  ResetStep _step = ResetStep.email;

  // ── Shared state ──
  String _email = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // ── Step 1: Email ──
  final _emailController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();

  // ── Step 2: OTP ──
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int? _remainingAttempts;
  int _resendTimer = 60;
  bool _canResend = false;
  Timer? _resendCountdown;

  // ── Step 3: New Password ──
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSuccess = false;

  // ── Animation ──
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // If email was passed from ForgotPasswordPage, skip email step
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _email = widget.initialEmail!;
      _emailController.text = widget.initialEmail!;
      _step = ResetStep.otp;
      _startResendTimer();
    }
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendCountdown?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  Step transitions
  // ─────────────────────────────────────────────
  void _goToStep(ResetStep step) {
    setState(() {
      _step = step;
      _errorMessage = null;
      _successMessage = null;
    });
    _slideController.reset();
    _slideController.forward();
  }

  // ─────────────────────────────────────────────
  //  STEP 1 — Request OTP
  // ─────────────────────────────────────────────
  Future<void> _requestOTP() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService
        .requestPasswordResetOTP(_emailController.text.trim());

    if (!mounted) return;

    if (result['success']) {
      _email = _emailController.text.trim();
      setState(() {
        _successMessage = result['message'];
        _isLoading = false;
      });
      _startResendTimer();
      _goToStep(ResetStep.otp);
    } else {
      setState(() {
        _errorMessage = result['message'];
        _isLoading = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  // ─────────────────────────────────────────────
  //  Step 2 — Resend OTP
  // ─────────────────────────────────────────────
  void _startResendTimer() {
    _resendCountdown?.cancel();
    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    _resendCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.resendPasswordResetOTP(_email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Clear OTP boxes
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      setState(() {
        _successMessage = result['message'];
        _remainingAttempts = null;
      });
      _startResendTimer();
      HapticFeedback.lightImpact();
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
      HapticFeedback.heavyImpact();
    }
  }

  // ─────────────────────────────────────────────
  //  Step 3 — Verify OTP + Reset Password
  // ─────────────────────────────────────────────
  Future<void> _verifyOTPAndReset() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final otpString = _otpControllers.map((c) => c.text).join();
    if (otpString.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authService.resetPasswordWithOTP(
      email: _email,
      otp: otpString,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _successMessage = result['message'];
      });
      HapticFeedback.lightImpact();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.push('/login');
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'];
        if (result['remaining_attempts'] != null) {
          _remainingAttempts = result['remaining_attempts'];
        }
      });
      HapticFeedback.heavyImpact();
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              Colors.white,
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 64 : 24,
                vertical: 32,
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
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
                        // Gradient header
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Center(
                              child: _buildStepIndicator(),
                            ),
                          ),
                        ),

                        // Page content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 140, 28, 32),
                          child: _buildCurrentStep(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Step indicator dots
  // ─────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final steps = [
      (ResetStep.email, Icons.email_outlined, 'Email'),
      (ResetStep.otp, Icons.pin_outlined, 'OTP'),
      (ResetStep.newPassword, Icons.lock_outline, 'Password'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final (step, icon, label) = entry.value;
        final isActive = _step == step;
        final isDone = _step.index > step.index;

        return Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 44 : 36,
                  height: isActive ? 44 : 36,
                  decoration: BoxDecoration(
                    color: isDone
                        ? Colors.white
                        : isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    isDone ? Icons.check : icon,
                    size: isActive ? 22 : 18,
                    color: isDone
                        ? Colors.green[600]
                        : isActive
                            ? AppTheme.primaryColor
                            : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isActive ? 1.0 : 0.6),
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (idx < steps.length - 1)
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: Colors.white.withOpacity(isDone ? 0.9 : 0.3),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  Route to the right step widget
  // ─────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_step) {
      case ResetStep.email:
        return _buildEmailStep();
      case ResetStep.otp:
        return _buildOtpStep();
      case ResetStep.newPassword:
        return _buildNewPasswordStep();
    }
  }

  // ─────────────────────────────────────────────
  //  STEP 1 — Email
  // ─────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset Password?',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address. We\'ll send a 6-digit OTP to reset your password.',
            style:
                TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _buildAlert(message: _errorMessage!, isError: true),
            const SizedBox(height: 16),
          ],
          _buildLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
            decoration: _inputDecoration(
              hint: 'you@example.com',
              prefixIcon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
            label: 'Send OTP',
            icon: Icons.send,
            onPressed: _isLoading ? null : _requestOTP,
            isLoading: _isLoading,
            loadingLabel: 'Sending OTP...',
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back,
                  size: 16, color: AppTheme.primaryColor),
              label: Text(
                'Back to Login',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  STEP 2 — OTP
  // ─────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style:
                TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _email,
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (_errorMessage != null) ...[
          _buildAlert(message: _errorMessage!, isError: true),
          if (_remainingAttempts != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '$_remainingAttempts attempt(s) remaining',
                style: TextStyle(color: Colors.orange[700], fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (_successMessage != null) ...[
          _buildAlert(message: _successMessage!, isError: false),
          const SizedBox(height: 16),
        ],

        // 6 OTP boxes — responsive width using Expanded
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 5 ? 6 : 0),
                child: SizedBox(
                  height: 56,
                  child: TextFormField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    enabled: !_isLoading,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
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
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) {
                        _otpFocusNodes[i + 1].requestFocus();
                      } else if (val.isEmpty && i > 0) {
                        _otpFocusNodes[i - 1].requestFocus();
                      }
                      // Auto-proceed when all 6 digits entered
                      final all =
                          _otpControllers.every((c) => c.text.isNotEmpty);
                      if (all) _goToStep(ResetStep.newPassword);
                    },
                  ),
                ), // SizedBox
              ), // Padding
            ); // Expanded
          }),
        ),

        const SizedBox(height: 28),

        // Next button
        _buildPrimaryButton(
          label: 'Verify OTP',
          icon: Icons.check_circle,
          onPressed: _isLoading
              ? null
              : () {
                  final all = _otpControllers.every((c) => c.text.isNotEmpty);
                  if (!all) {
                    setState(() => _errorMessage = 'Please enter all 6 digits');
                  } else {
                    setState(() => _errorMessage = null);
                    _goToStep(ResetStep.newPassword);
                  }
                },
          isLoading: _isLoading,
          loadingLabel: 'Verifying...',
        ),

        const SizedBox(height: 20),

        // Resend row
        Center(
          child: _canResend
              ? TextButton(
                  onPressed: _resendOTP,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                )
              : Text(
                  'Resend OTP in ${_resendTimer}s',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
        ),

        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => _goToStep(ResetStep.email),
            icon: Icon(Icons.arrow_back, size: 16, color: Colors.grey[600]),
            label: Text(
              'Change email',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  STEP 3 — New Password
  // ─────────────────────────────────────────────
  Widget _buildNewPasswordStep() {
    if (_isSuccess) {
      return Column(
        children: [
          const SizedBox(height: 16),
          Icon(Icons.check_circle_outline, size: 72, color: Colors.green[500]),
          const SizedBox(height: 20),
          const Text(
            'Password Reset!',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildAlert(message: _successMessage!, isError: false),
          const SizedBox(height: 28),
          Text(
            'Redirecting to login...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/login'),
            child: Text(
              'Go to Login Now',
              style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set New Password',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a strong password with at least 8 characters.',
            style:
                TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _buildAlert(message: _errorMessage!, isError: true),
            const SizedBox(height: 16),
          ],

          // New Password
          _buildLabel('New Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            enabled: !_isLoading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 8) return 'Minimum 8 characters';
              if (!RegExp(r'(?=.*[a-z])').hasMatch(v)) {
                return 'Must contain at least one lowercase letter';
              }
              if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) {
                return 'Must contain at least one uppercase letter';
              }
              if (!RegExp(r'(?=.*\d)').hasMatch(v)) {
                return 'Must contain at least one number';
              }
              return null;
            },
            decoration: _inputDecoration(
              hint: 'Enter new password',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Confirm Password
          _buildLabel('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            enabled: !_isLoading,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: _inputDecoration(
              hint: 'Confirm new password',
              prefixIcon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[600],
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Password strength hint
          _buildPasswordHints(),

          const SizedBox(height: 28),

          _buildPrimaryButton(
            label: 'Reset Password',
            icon: Icons.check_circle,
            onPressed: _isLoading ? null : _verifyOTPAndReset,
            isLoading: _isLoading,
            loadingLabel: 'Resetting...',
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () => _goToStep(ResetStep.otp),
              icon: Icon(Icons.arrow_back, size: 16, color: Colors.grey[600]),
              label: Text(
                'Back to OTP',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Shared helpers
  // ─────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        children: [
          TextSpan(text: '$text '),
          const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor),
      suffixIcon: suffix,
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
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isLoading,
    required String loadingLabel,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20, height: 20, child: LogoLoader()),
                  const SizedBox(width: 12),
                  Text(loadingLabel,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
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
                  color: isError ? Colors.red[700] : Colors.green[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordHints() {
    final pw = _newPasswordController.text;
    final checks = [
      ('At least 8 characters', pw.length >= 8),
      ('One uppercase letter', RegExp(r'[A-Z]').hasMatch(pw)),
      ('One lowercase letter', RegExp(r'[a-z]').hasMatch(pw)),
      ('One number', RegExp(r'\d').hasMatch(pw)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: checks.map((check) {
        final (label, passed) = check;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: passed ? Colors.green[600] : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: passed ? Colors.green[700] : Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
