// lib/presentation/pages/contact/contact_us_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../shared/custom_app_bar.dart';
import '../shared/custom_bottom_nav.dart';
import 'widgets/contact_info_card.dart';
import 'widgets/contact_form_widget.dart';
import 'widgets/business_hours_card.dart';
import 'widgets/quick_actions_widget.dart';
import 'package:anu_app/utils/app_notifications.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorMessage('Could not open $url');
      }
    } catch (e) {
      _showErrorMessage('Error opening link: $e');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    await _launchUrl(url);
  }

  Future<void> _sendEmail(String email) async {
    final url = 'mailto:$email?subject=Customer Support Inquiry';
    await _launchUrl(url);
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      AppNotifications.showSuccess(context, 'Success message');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Contact Us',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              _shareContactInfo();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh contact information if needed
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              _buildHeroSection(),

              const SizedBox(height: 24),

              // Quick Actions
              QuickActionsWidget(
                onCallPressed: () => _makePhoneCall('+918076148120'),
                onEmailPressed: () => _sendEmail('customercare@anugami.com'),
                onWhatsAppPressed: () =>
                    _launchUrl('https://wa.me/918076148120'),
              ),

              const SizedBox(height: 24),

              // Contact Information Cards
              if (isTablet) _buildTabletLayout() else _buildMobileLayout(),

              const SizedBox(height: 24),

              // Contact Form
              ContactFormWidget(
                onFormSubmitted: (success, message) {
                  if (success) {
                    _showSuccessMessage(message);
                  } else {
                    _showErrorMessage(message);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Additional Information
              _buildAdditionalInfo(),

              const SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      // ✅ FIXED: Remove const and use direct index number
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4, // Profile tab index (hard-coded to avoid const issues)
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Were Here to Help!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Got a question or need assistance? Our customer support team is ready to help you with orders, returns, account issues, and more.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Response time: Within 24-48 hours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        ContactInfoCard(
          onCallPressed: () => _makePhoneCall('+918076148120'),
          onEmailPressed: () => _sendEmail('customercare@anugami.com'),
        ),
        const SizedBox(height: 16),
        const BusinessHoursCard(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ContactInfoCard(
            onCallPressed: () => _makePhoneCall('+918076148120'),
            onEmailPressed: () => _sendEmail('customercare@anugami.com'),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: BusinessHoursCard(),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
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
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.language,
              'Language Support',
              'Hindi, English',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.payment,
              'Payment Issues',
              'Contact us for refund and payment related queries',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.local_shipping,
              'Shipping Support',
              'Track orders, delivery issues, and returns',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.account_circle,
              'Account Help',
              'Login issues, profile updates, and security',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _shareContactInfo() {
    final contactInfo = '''
Anugami Customer Support

📞 Phone: +91 807 614 8120
📧 Email: customercare@anugami.com

🏢 Office Address:
Anugami Headquarters
1407 Bhajan Park, Maruti Kunj Rd
Bhondsi, Gurgaon
Haryana 122102, India

🕒 Business Hours:
Monday - Friday: 9:00 AM - 6:00 PM
Saturday: 10:00 AM - 4:00 PM IST
Sunday: Closed

Download our app for 24/7 support!
''';

    try {
      Clipboard.setData(ClipboardData(text: contactInfo));
      _showSuccessMessage('Contact information copied to clipboard');
    } catch (e) {
      _showErrorMessage('Failed to copy contact information');
    }
  }
}
