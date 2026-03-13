import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class NotificationPreferencePage extends StatefulWidget {
  const NotificationPreferencePage({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencePage> createState() =>
      _NotificationPreferencePageState();
}

class _NotificationPreferencePageState
    extends State<NotificationPreferencePage> {
  // ORDER NOTIFICATIONS
  bool orderConfirmed = true;
  bool orderPacked = true;
  bool outForDelivery = true;
  bool orderDelivered = true;

  // OFFER NOTIFICATIONS
  bool dailyDeals = true;
  bool priceDrops = false;
  bool cashbackOffers = true;

  // APP ACTIVITY
  bool recommendations = true;
  bool securityAlerts = true;
  bool chatMessages = false;

  @override

  // HEADER WITH GRADIENT + LOGO
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Preferences"),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          // BACKGROUND PATTERN
          CustomPaint(
            size: Size.infinite,
            painter: PatternPainter(),
          ),
          // CONTENT
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildSettingsCard(),
          ),
        ],
      ),
    );
  }

  // MAIN SETTINGS CARD
  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Order Notifications"),
          _switchTile("Order Confirmed", orderConfirmed, (v) {
            setState(() => orderConfirmed = v);
          }),
          _switchTile("Order Packed", orderPacked, (v) {
            setState(() => orderPacked = v);
          }),
          _switchTile("Out for Delivery", outForDelivery, (v) {
            setState(() => outForDelivery = v);
          }),
          _switchTile("Delivered", orderDelivered, (v) {
            setState(() => orderDelivered = v);
          }),
          const SizedBox(height: 24),
          _sectionTitle("Offers & Deals"),
          _switchTile("Daily Deals", dailyDeals, (v) {
            setState(() => dailyDeals = v);
          }),
          _switchTile("Price Drop Alerts", priceDrops, (v) {
            setState(() => priceDrops = v);
          }),
          _switchTile("Wallet Cashback Offers", cashbackOffers, (v) {
            setState(() => cashbackOffers = v);
          }),
          const SizedBox(height: 24),
          _sectionTitle("App Activity"),
          _switchTile("Recommendations", recommendations, (v) {
            setState(() => recommendations = v);
          }),
          _switchTile("Security Alerts", securityAlerts, (v) {
            setState(() => securityAlerts = v);
          }),
          _switchTile("Chat Messages", chatMessages, (v) {
            setState(() => chatMessages = v);
          }),
        ],
      ),
    );
  }

  // SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  // SWITCH ITEM
  Widget _switchTile(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

// SAME PATTERN PAINTER FROM FORGOT PASSWORD PAGE
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        final x = (size.width / 10) * i;
        final y = (size.height / 10) * j;
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
