// lib/presentation/pages/contact/widgets/business_hours_card.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class BusinessHoursCard extends StatelessWidget {
  const BusinessHoursCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final businessHours = [
      {
        'day': 'Monday - Friday ',
        'hours': '9AM - 6PM',
        'isToday': _isWeekday()
      },
      {'day': 'Saturday', 'hours': '10AM - 4PM', 'isToday': _isSaturday()},
      {'day': 'Sunday', 'hours': 'Closed', 'isToday': _isSunday()},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Business Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Status
            _buildCurrentStatus(),

            const SizedBox(height: 16),

            // Hours List
            ...businessHours.map((item) => _buildHoursItem(
                  day: item['day']! as String,
                  hours: item['hours']! as String,
                  isToday: item['isToday']! as bool,
                )),

            const SizedBox(height: 16),

            // Response Time Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Response Times',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildResponseTime('Phone Support', 'During business hours'),
                  const SizedBox(height: 4),
                  _buildResponseTime('Email Support', 'Within 24-48 hours'),
                  const SizedBox(height: 4),
                  _buildResponseTime('WhatsApp', 'Within 2-6 hours'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Emergency Contact Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'For urgent order-related issues, please call us directly during business hours.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final isOpen = _isCurrentlyOpen();
    final statusText = isOpen ? 'We\'re Open' : 'We\'re Closed';
    final statusColor = isOpen ? Colors.green : Colors.red;
    final nextOpenTime = _getNextOpenTime();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor.shade700,
                  ),
                ),
                if (!isOpen && nextOpenTime.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    nextOpenTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursItem({
    required String day,
    required String hours,
    required bool isToday,
  }) {
    final isClosed = hours.toLowerCase().contains('closed');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isToday) ...[
                Icon(
                  Icons.today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: isToday ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              color: isClosed
                  ? Colors.red.shade600
                  : isToday
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTime(String method, String time) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$method: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  bool _isCurrentlyOpen() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;

    // Monday to Friday: 9 AM to 6 PM (9-18)
    if (weekday >= 1 && weekday <= 5) {
      return hour >= 9 && hour < 18;
    }
    // Saturday: 10 AM to 4 PM (10-16)
    else if (weekday == 6) {
      return hour >= 10 && hour < 16;
    }
    // Sunday: Closed
    else {
      return false;
    }
  }

  bool _isWeekday() {
    final weekday = DateTime.now().weekday;
    return weekday >= 1 && weekday <= 5;
  }

  bool _isSaturday() {
    return DateTime.now().weekday == 6;
  }

  bool _isSunday() {
    return DateTime.now().weekday == 7;
  }

  String _getNextOpenTime() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;

    if (weekday >= 1 && weekday <= 5) {
      // Monday to Friday
      if (hour < 9) {
        return 'Opens at 9:00 AM today';
      } else if (hour >= 18) {
        return weekday == 5 ? 'Opens Monday 9:00 AM' : 'Opens tomorrow 9:00 AM';
      }
    } else if (weekday == 6) {
      // Saturday
      if (hour < 10) {
        return 'Opens at 10:00 AM today';
      } else if (hour >= 16) {
        return 'Opens Monday 9:00 AM';
      }
    } else {
      // Sunday
      return 'Opens Monday 9:00 AM';
    }

    return '';
  }
}
