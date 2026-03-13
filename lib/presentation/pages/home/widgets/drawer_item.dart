// lib/presentation/pages/home/widgets/drawer_item.dart
import 'package:flutter/material.dart';
import 'package:anu_app/config/theme.dart';

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }
}
