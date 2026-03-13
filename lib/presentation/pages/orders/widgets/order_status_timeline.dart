// lib/presentation/pages/orders/widgets/order_status_timeline.dart
import 'package:flutter/material.dart';
import '../../../../core/models/order_model.dart';
import '../../../../config/theme.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderModel order;

  const OrderStatusTimeline({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Order Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Placed on ${order.formattedCreatedDate}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCurrentStatusBadge(),
              ],
            ),

            const SizedBox(height: 24),

            // Timeline
            _buildTimeline(),

            // ✅ FIX: Cancellation Info - Show ONLY if can_cancel is true AND status is NOT cancelled
            if (order.canBeCancelled &&
                order.status.toLowerCase() != 'cancelled') ...[
              const SizedBox(height: 20),
              _buildCancellationInfo(),
            ],

            // ✅ NEW: Payment Pending Warning
            if (order.status.toLowerCase() == 'pending' &&
                order.payment?.isPaid != true) ...[
              const SizedBox(height: 20),
              _buildPaymentPendingWarning(),
            ],

            // Order Summary
            const SizedBox(height: 20),
            _buildOrderSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusBadge() {
    Color statusColor;
    IconData statusIcon;

    switch (order.status.toLowerCase()) {
      case 'delivered':
        statusColor = const Color(0xFFF96A4C);
        statusIcon = Icons.check_circle;
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      case 'processing':
        statusColor = Colors.purple;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        statusColor = Colors.lightBlue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'returned':
        statusColor = Colors.deepOrange;
        statusIcon = Icons.keyboard_return;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Text(
            _capitalizeFirst(order.status),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final timelineSteps = _getTimelineSteps();

    return Column(
      children: timelineSteps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == timelineSteps.length - 1;

        return Row(
          children: [
            // Timeline Indicator
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: step['isCompleted']
                        ? AppTheme.primaryColor
                        : step['isCurrent']
                            ? AppTheme.primaryColor
                            : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: step['isCompleted'] || step['isCurrent']
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: step['isCompleted']
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : step['isCurrent']
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step['isCompleted']
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Timeline Content
            Expanded(
              child: Container(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: step['isCompleted'] || step['isCurrent']
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (step['subtitle'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (step['timestamp'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        step['timestamp'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
    );
  }

  List<Map<String, dynamic>> _getTimelineSteps() {
    final currentStatus = order.status.toLowerCase();

    // ✅ FIX: For cancelled orders, show special timeline
    if (currentStatus == 'cancelled') {
      return [
        {
          'title': 'Order Placed',
          'subtitle': 'Your order was received',
          'timestamp': order.formattedCreatedDate,
          'isCompleted': true,
          'isCurrent': false,
        },
        {
          'title': 'Order Cancelled',
          'subtitle': 'Order has been cancelled',
          'timestamp': null, // ✅ FIX: Removed formattedUpdatedDate
          'isCompleted': true,
          'isCurrent': false,
        },
      ];
    }

    // ✅ FIX: For returned orders
    if (currentStatus == 'returned') {
      return [
        {
          'title': 'Order Placed',
          'subtitle': 'Your order was received',
          'timestamp': order.formattedCreatedDate,
          'isCompleted': true,
          'isCurrent': false,
        },
        {
          'title': 'Delivered',
          'subtitle': 'Order was delivered',
          'timestamp': null,
          'isCompleted': true,
          'isCurrent': false,
        },
        {
          'title': 'Returned',
          'subtitle': 'Order has been returned',
          'timestamp': null, // ✅ FIX: Removed formattedUpdatedDate
          'isCompleted': true,
          'isCurrent': false,
        },
      ];
    }

    // ✅ Normal order flow
    return [
      {
        'title': 'Order Placed',
        'subtitle': 'Your order has been received',
        'timestamp': order.formattedCreatedDate,
        'isCompleted': true,
        'isCurrent': currentStatus == 'pending', // ✅ FIX: Pending stays here
      },
      {
        'title': 'Order Confirmed',
        'subtitle': order.payment?.isPaid == true
            ? 'Payment confirmed'
            : 'Awaiting payment confirmation',
        'timestamp':
            order.payment?.isPaid == true ? order.formattedCreatedDate : null,
        'isCompleted': ['confirmed', 'processing', 'shipped', 'delivered']
            .contains(currentStatus),
        'isCurrent': false, // ✅ FIX: Never current, only completed or not
      },
      {
        'title': 'Processing',
        'subtitle': 'Preparing your order for shipment',
        'timestamp': null,
        'isCompleted':
            ['processing', 'shipped', 'delivered'].contains(currentStatus),
        'isCurrent':
            currentStatus == 'confirmed', // ✅ FIX: Current when confirmed
      },
      {
        'title': 'Shipped',
        'subtitle': order.shipping?.courierName != null
            ? 'Shipped via ${order.shipping!.courierName}'
            : 'Your order is on the way',
        'timestamp': order.shipping?.courierAssignedAt != null
            ? _formatDate(order.shipping!.courierAssignedAt!)
            : null,
        'isCompleted': ['shipped', 'delivered'].contains(currentStatus),
        'isCurrent': currentStatus == 'processing',
      },
      {
        'title': 'Delivered',
        'subtitle': 'Order delivered successfully',
        'timestamp':
            currentStatus == 'delivered' ? order.formattedCreatedDate : null,
        'isCompleted': currentStatus == 'delivered',
        'isCurrent': currentStatus == 'shipped',
      },
    ];
  }

  // ✅ NEW: Payment Pending Warning
  Widget _buildPaymentPendingWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Pending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your order is waiting for payment confirmation. Once payment is verified, your order will be confirmed and processed.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Cancellation Window',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can cancel this order within 24 hours of placing it.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Time remaining: ${order.timeRemainingToCancel}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                order.formattedTotalAmount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.totalItemsCount} items',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Order #${order.orderNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
