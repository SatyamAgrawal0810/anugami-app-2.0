// lib/presentation/pages/profile/widgets/profile_header.dart

import 'package:flutter/material.dart';
import 'package:anu_app/config/theme.dart';
import '../../../../core/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profileData;

  const ProfileHeader({
    Key? key,
    required this.profileData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Stack(
        children: [
          // ✨ Background pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: ProfileHeaderPatternPainter(),
            ),
          ),

          // 🔹 Original content (UNCHANGED)
          Column(
            children: [
              // Profile picture
              profileData.profilePicture != null
                  ? CircleAvatar(
                      radius: 48, // unchanged
                      backgroundImage:
                          NetworkImage(profileData.profilePicture!),
                    )
                  : const CircleAvatar(
                      radius: 48, // unchanged
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),

              const SizedBox(height: 12),

              // User name
              Text(
                profileData.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                profileData.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ✨ Subtle premium background pattern
class ProfileHeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    const double radius = 4;
    const double gap = 30;

    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
