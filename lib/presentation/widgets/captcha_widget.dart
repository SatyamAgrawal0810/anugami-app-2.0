// lib/presentation/widgets/captcha_widget.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:anu_app/config/theme.dart';

class CaptchaValue {
  final String captchaId;
  final String captchaAnswer;
  const CaptchaValue({required this.captchaId, required this.captchaAnswer});
}

class CaptchaWidget extends StatefulWidget {
  final void Function(CaptchaValue?) onVerify;
  final String? externalError;

  const CaptchaWidget({
    Key? key,
    required this.onVerify,
    this.externalError,
  }) : super(key: key);

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  final _answerController = TextEditingController();

  // ✅ Hardcoded — String.fromEnvironment is compile-time only, not runtime
  static const _baseUrl = 'https://anugami.com/api/v1';

  String? _captchaId;
  Uint8List? _imageBytes;
  bool _isLoading =
      true; // ✅ true by default — shows shimmer before postFrameCallback fires
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: defer to post-frame so we don't setState during parent's build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchCaptcha();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptcha() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _fetchError = null;
      _captchaId = null;
      _imageBytes = null;
      _answerController.clear();
    });
    widget.onVerify(null);

    try {
      developer.log('🔒 Fetching CAPTCHA...');
      final res = await http.get(
        Uri.parse('$_baseUrl/captcha/generate/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      developer.log('🔒 CAPTCHA status: ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        // ✅ Log full response so we can see exact keys
        developer.log('🔒 CAPTCHA full response: ${res.body}');

        final captchaId = data['captcha_id'] as String?;

        // ✅ Correct field name from backend is "image_b64"
        String? raw = data['image_b64'] as String? ??
            data['image_base64'] as String? ??
            data['image'] as String? ??
            data['captcha_image'] as String?;

        developer.log(
            '🔒 captcha_id: $captchaId | image field found: ${raw != null} | raw length: ${raw?.length}');

        if (captchaId == null || raw == null || raw.isEmpty) {
          developer.log(
              '🔒 CAPTCHA: missing captcha_id or image. Keys: ${data.keys.toList()}');
          setState(() {
            _fetchError = 'Invalid CAPTCHA response. Tap ↻ to retry.';
            _isLoading = false;
          });
          return;
        }

        // ✅ KEY FIX: Strip "data:image/png;base64," prefix if present
        if (raw.contains(',')) {
          raw = raw.split(',').last;
        }

        // ✅ Safe base64 decode
        Uint8List bytes;
        try {
          bytes = base64Decode(raw);
        } catch (e) {
          developer.log('🔒 base64Decode failed: $e');
          setState(() {
            _fetchError = 'Could not decode CAPTCHA image. Tap ↻ to retry.';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _captchaId = captchaId;
          _imageBytes = bytes;
          _isLoading = false;
        });
      } else {
        developer.log('🔒 CAPTCHA error: ${res.body}');
        setState(() {
          _fetchError =
              'Failed to load CAPTCHA (${res.statusCode}). Tap ↻ to retry.';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('🔒 CAPTCHA exception: $e');
      if (!mounted) return;
      setState(() {
        _fetchError = 'Network error. Tap ↻ to retry.';
        _isLoading = false;
      });
    }
  }

  void _onAnswerChanged(String value) {
    if (_captchaId == null) return;
    if (value.trim().isNotEmpty) {
      widget.onVerify(CaptchaValue(
        captchaId: _captchaId!,
        captchaAnswer: value.trim(),
      ));
    } else {
      widget.onVerify(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.externalError != null || _fetchError != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? Colors.red.shade300
              : AppTheme.primaryColor.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.security, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              const Text(
                'Security Check',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Image + refresh button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageContent(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Refresh
              GestureDetector(
                onTap: _isLoading ? null : _fetchCaptcha,
                child: Container(
                  width: 44,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : Icon(Icons.refresh_rounded,
                            color: AppTheme.primaryColor, size: 24),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Answer input
          TextField(
            controller: _answerController,
            onChanged: _onAnswerChanged,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Type the characters shown above',
              hintStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
                letterSpacing: 0,
                fontWeight: FontWeight.normal,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                borderSide: BorderSide(
                  color: hasError ? Colors.red : AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          // Error text
          if (widget.externalError != null || _fetchError != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.externalError ?? _fetchError!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (_fetchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined,
                size: 22, color: Colors.grey.shade400),
            const SizedBox(height: 2),
            Text('Tap ↻ to retry',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) {
          developer.log('🔒 Image.memory render error: $error');
          return Center(
            child: Text('Image error',
                style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
