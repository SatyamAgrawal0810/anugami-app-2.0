// lib/presentation/pages/auth/otp_verification_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../providers/user_provider.dart';
import '../../../api/services/auth_service.dart';
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import 'package:anu_app/utils/app_notifications.dart';
import 'package:anu_app/presentation/widgets/captcha_widget.dart'; // ✅

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String fullName;
  final bool isRegistration;
  final Function(BuildContext)? onVerificationSuccess;

  const OtpVerificationPage({
    Key? key,
    required this.email,
    required this.fullName,
    this.isRegistration = true,
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  bool _canResend = false;
  int? _remainingAttempts;

  // ✅ CAPTCHA state — shown after 5 failed OTP attempts
  bool _showCaptcha = false;
  CaptchaValue? _captchaValue;
  String? _captchaError;
  int _captchaKey = 0; // increment to force CaptchaWidget rebuild

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 300;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool _isOTPComplete() => _getOTP().length == 6;

  void _clearOTP() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete()) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      return;
    }

    // ✅ If CAPTCHA visible, enforce it before calling API
    if (_showCaptcha && _captchaValue == null) {
      setState(() => _captchaError = 'Please complete the security check.');
      return;
    }

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _captchaError = null;
      });
    }

    try {
      developer.log('Verifying OTP for email: ${widget.email}');

      // ✅ Pass captchaId + captchaAnswer if present
      final result = await _authService.verifyOTP(
        widget.email,
        _getOTP(),
        captchaId: _captchaValue?.captchaId,
        captchaAnswer: _captchaValue?.captchaAnswer,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        developer.log('OTP verified successfully');

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userData = await _authService.getUserData();
        if (userData != null) {
          userProvider.setUserData(userData);
        }

        AppNotifications.showSuccess(context, 'Success message');
        await Future.delayed(const Duration(milliseconds: 500));

        if (widget.onVerificationSuccess != null) {
          widget.onVerificationSuccess!(context);
        } else {
          if (mounted) Navigator.of(context).pop();
        }
      } else {
        // ✅ Backend says CAPTCHA required (5+ failed OTP attempts)
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
          _errorMessage = result['message'] ?? 'Invalid OTP. Please try again.';
          _remainingAttempts = result['remaining_attempts'];
        });

        _clearOTP();

        if (_remainingAttempts != null && !_showCaptcha) {
          setState(() {
            _errorMessage =
                '$_errorMessage ($_remainingAttempts attempts remaining)';
          });
        }
      }
    } catch (e) {
      developer.log('Error during OTP verification: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
        _clearOTP();
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    if (mounted) {
      setState(() {
        _isResending = true;
        _errorMessage = null;
      });
    }

    try {
      developer.log('Resending OTP to email: ${widget.email}');
      final result = await _authService.resendOTP(widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      if (result['success']) {
        developer.log('OTP resent successfully');
        AppNotifications.showSuccess(context, 'Success message');
        _startResendTimer();
        _clearOTP();

        // ✅ Backend resets attempt counter on resend — hide CAPTCHA
        setState(() {
          _showCaptcha = false;
          _captchaValue = null;
          _captchaKey++;
          _captchaError = null;
        });
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      developer.log('Error resending OTP: $e');
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend OTP. Please try again.';
        });
      }
    }
  }

  void _onOTPChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_isOTPComplete()) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _verifyOTP();
          });
        }
      }
    }
  }

  void _onOTPKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_otpControllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: Text(
          widget.isRegistration ? 'Verify Your Email' : 'Email Verification',
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Email verification icon
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF96A4C).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 60,
                    color: Color(0xFFF96A4C),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  widget.isRegistration
                      ? 'Verify Your Email'
                      : 'Verify Your Account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(
                        text: 'We\'ve sent a 6-digit verification code to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // OTP Input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      List.generate(6, (index) => _buildOtpTextField(index)),
                ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ✅ CAPTCHA — shown after 5 failed OTP attempts
                if (_showCaptcha) ...[
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
                  const SizedBox(height: 16),
                ],

                // Verify button
                ElevatedButton(
                  onPressed: (_isLoading ||
                          !_isOTPComplete() ||
                          (_showCaptcha && _captchaValue == null))
                      ? null
                      : _verifyOTP,
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
                      gradient: (_isLoading ||
                              !_isOTPComplete() ||
                              (_showCaptcha && _captchaValue == null))
                          ? null
                          : AppTheme.primaryGradient,
                      color: (_isLoading ||
                              !_isOTPComplete() ||
                              (_showCaptcha && _captchaValue == null))
                          ? Colors.grey
                          : null,
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
                          : Text(
                              widget.isRegistration
                                  ? 'Verify & Complete Registration'
                                  : 'Verify Account',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resend code option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Didn\'t receive the code? ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: _canResend && !_isResending ? _resendOTP : null,
                      child: Text(
                        _isResending
                            ? 'Sending...'
                            : _canResend
                                ? 'Resend Code'
                                : 'Resend (${_formatTime(_resendCountdown)})',
                        style: TextStyle(
                          fontSize: 14,
                          color: _canResend && !_isResending
                              ? const Color(0xFFF96A4C)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Help section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF96A4C).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF96A4C).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFF96A4C),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check your email inbox and spam folder',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFF96A4C),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If you still don\'t receive the code, please try resending or contact support.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpTextField(int index) {
    return SizedBox(
      width: 45,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onOTPKeyPressed(event, index),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          onChanged: (value) => _onOTPChanged(value, index),
          onTap: () {
            _otpControllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _otpControllers[index].text.length,
            );
          },
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _errorMessage != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _errorMessage != null
                    ? Colors.red
                    : const Color(0xFFF96A4C),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: _errorMessage != null
                ? Colors.red.withOpacity(0.05)
                : Colors.grey[50],
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
  }
}
