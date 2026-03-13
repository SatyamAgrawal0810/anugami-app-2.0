// lib/presentation/widgets/order_tracking_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/services/order_service.dart';
import '../../core/models/order_model.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

class OrderTrackingDialog extends StatefulWidget {
  final OrderModel order;
  final OrderService orderService;

  const OrderTrackingDialog({
    Key? key,
    required this.order,
    required this.orderService,
  }) : super(key: key);

  @override
  State<OrderTrackingDialog> createState() => _OrderTrackingDialogState();
}

class _OrderTrackingDialogState extends State<OrderTrackingDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _trackingData;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.orderService.trackOrder(widget.order.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success']) {
            _trackingData = result['data'];
          } else {
            _error = result['message'] ?? 'Failed to load tracking data';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error loading tracking data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEAF4E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.order.orderNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: const LogoLoader(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTrackingData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEAF4E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatus(),
            const SizedBox(height: 16),
            _buildShippingDetails(),
            const SizedBox(height: 16),
            _buildTrackingHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final currentStatus =
        _trackingData?['current_status'] ?? widget.order.status;
    final statusTime = _trackingData?['status_time'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(currentStatus),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(currentStatus),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatStatus(currentStatus),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(currentStatus),
                    ),
                  ),
                  if (statusTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(statusTime),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetails() {
    final awbNumber = _trackingData?['awb_number'];
    final courier = _trackingData?['courier'];
    final expectedDelivery = _trackingData?['expected_delivery_date'];

    if (awbNumber == null && courier == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (courier != null) ...[
              _buildDetailRow('Courier', courier),
              const SizedBox(height: 8),
            ],
            if (awbNumber != null) ...[
              _buildDetailRow('AWB Number', awbNumber),
              const SizedBox(height: 8),
            ],
            if (expectedDelivery != null) ...[
              _buildDetailRow(
                  'Expected Delivery', _formatDate(expectedDelivery)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingHistory() {
    final scanDetails = _trackingData?['scan_details'] as List<dynamic>?;

    if (scanDetails == null || scanDetails.isEmpty) {
      return _buildBasicTimeline();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracking History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: scanDetails.length,
          itemBuilder: (context, index) {
            final detail = scanDetails[index];
            final isLast = index == scanDetails.length - 1;
            return _buildTimelineItem(detail, isLast);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> detail, bool isLast) {
    final status = detail['status'] ?? '';
    final location = detail['location'] ?? '';
    final timestamp = detail['timestamp'] ?? detail['date'];
    final activity = detail['activity'] ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(status),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activity.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDateTime(timestamp),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicTimeline() {
    final currentStatus =
        _trackingData?['current_status'] ?? widget.order.status;

    final statuses = [
      {'key': 'pending', 'label': 'Order Placed'},
      {'key': 'confirmed', 'label': 'Order Confirmed'},
      {'key': 'processing', 'label': 'Processing'},
      {'key': 'shipped', 'label': 'Shipped'},
      {'key': 'delivered', 'label': 'Delivered'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: statuses.map((statusMap) {
            final statusKey = statusMap['key']!;
            final statusLabel = statusMap['label']!;
            final isCompleted = _isStatusCompleted(statusKey, currentStatus);
            final isCurrent = _isCurrentStatus(statusKey, currentStatus);
            final isLast = statusKey == 'delivered';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? const Color(0xFFFEAF4E)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            )
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted
                            ? const Color(0xFFFEAF4E)
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCompleted || isCurrent
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFEAF4E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isStatusCompleted(String statusKey, String currentStatus) {
    final statusOrder = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered'
    ];
    final currentIndex = statusOrder.indexOf(currentStatus.toLowerCase());
    final statusIndex = statusOrder.indexOf(statusKey);

    return currentIndex >= statusIndex && currentIndex != -1;
  }

  bool _isCurrentStatus(String statusKey, String currentStatus) {
    return statusKey.toLowerCase() == currentStatus.toLowerCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFFF96A4C);
      case 'shipped':
      case 'out for delivery':
        return Colors.blue;
      case 'processing':
      case 'confirmed':
        return const Color(0xFFFEAF4E);
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'shipped':
      case 'out for delivery':
        return Icons.local_shipping;
      case 'processing':
      case 'confirmed':
        return Icons.inventory;
      case 'cancelled':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) {
      return word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1).toLowerCase()
          : word;
    }).join(' ');
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
