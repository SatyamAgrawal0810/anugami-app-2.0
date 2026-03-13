// lib/presentation/pages/orders/widgets/order_filter_sheet.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class OrderFilterSheet extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const OrderFilterSheet({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Orders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status options
                  ..._buildStatusOptions(),

                  const SizedBox(height: 32),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildStatusOptions() {
    final statusOptions = [
      {
        'value': 'all',
        'label': 'All Orders',
        'icon': Icons.list_alt,
        'count': null
      },
      {
        'value': 'pending',
        'label': 'Pending',
        'icon': Icons.pending,
        'count': null
      },
      {
        'value': 'confirmed',
        'label': 'Confirmed',
        'icon': Icons.check_circle_outline,
        'count': null
      },
      {
        'value': 'processing',
        'label': 'Processing',
        'icon': Icons.hourglass_empty,
        'count': null
      },
      {
        'value': 'shipped',
        'label': 'Shipped',
        'icon': Icons.local_shipping,
        'count': null
      },
      {
        'value': 'delivered',
        'label': 'Delivered',
        'icon': Icons.check_circle,
        'count': null
      },
      {
        'value': 'cancelled',
        'label': 'Cancelled',
        'icon': Icons.cancel_outlined,
        'count': null
      },
      {
        'value': 'returned',
        'label': 'Returned',
        'icon': Icons.keyboard_return,
        'count': null
      },
    ];

    return statusOptions.map((option) {
      final isSelected = selectedStatus == option['value'];

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => onStatusChanged(option['value'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option['icon'] as IconData,
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          isSelected ? AppTheme.primaryColor : Colors.black87,
                    ),
                  ),
                ),
                if (option['count'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${option['count']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                if (isSelected && option['count'] == null)
                  Icon(
                    Icons.check,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
