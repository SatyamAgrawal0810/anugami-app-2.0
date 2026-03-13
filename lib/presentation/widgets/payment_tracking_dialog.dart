import 'package:anu_app/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';
import '../../api/services/order_service.dart';

class PaymentTrackingDialog extends StatefulWidget {
  final int orderId;
  final String transactionId;
  final OrderService orderService;
  final Function(bool success) onPaymentComplete;

  const PaymentTrackingDialog({
    Key? key,
    required this.orderId,
    required this.transactionId,
    required this.orderService,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentTrackingDialog> createState() => _PaymentTrackingDialogState();
}

class _PaymentTrackingDialogState extends State<PaymentTrackingDialog> {
  String _status = 'Checking payment status...';
  bool _isSuccess = false;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _checkOrderStatus();
  }

  Future<void> _checkOrderStatus() async {
    try {
      final status = await widget.orderService.getOrderStatus(widget.orderId);

      if (!mounted) return;

      setState(() {
        if (status == 'confirmed' ||
            status == 'processing' ||
            status == 'shipped') {
          _status = 'Payment successful!';
          _isSuccess = true;
          _isComplete = true;
        } else if (status == 'cancelled' || status == 'failed') {
          _status = 'Payment failed. Please try again.';
          _isSuccess = false;
          _isComplete = true;
        } else {
          _status = 'Payment pending...';
        }
      });

      if (_isComplete) {
        await Future.delayed(const Duration(seconds: 1));
        widget.onPaymentComplete(_isSuccess);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Unable to verify payment.';
        _isSuccess = false;
        _isComplete = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      widget.onPaymentComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isComplete)
              const LogoLoader()
            else
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error,
                color: _isSuccess ? const Color(0xFFF96A4C) : Colors.red,
                size: 64,
              ),
            const SizedBox(height: 24),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isComplete)
              Text(
                'Transaction ID: ${widget.transactionId}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            if (_isComplete) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => widget.onPaymentComplete(_isSuccess),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
