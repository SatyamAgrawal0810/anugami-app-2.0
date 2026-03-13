// lib/presentation/pages/home/widgets/section_title.dart
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class SectionTitle extends StatefulWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionTitle({
    Key? key,
    required this.title,
    this.onViewAll,
  }) : super(key: key);

  @override
  State<SectionTitle> createState() => _SectionTitleState();
}

class _SectionTitleState extends State<SectionTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _controller.forward();
    if (mounted) widget.onViewAll?.call();
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // ── View All — no box, just text color changes on tap ─────────
          ViewAllButton(anim: _anim, onTap: _onTap),
        ],
      ),
    );
  }
}

// ── Reusable View All button (no box, gradient text on click) ─────────────────
class ViewAllButton extends StatelessWidget {
  final Animation<double> anim;
  final VoidCallback onTap;

  const ViewAllButton({
    Key? key,
    required this.anim,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: AnimatedBuilder(
          animation: anim,
          builder: (context, _) {
            final t = anim.value;
            // t=0 → black87, t=1 → gradient colors
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color.lerp(Colors.black87, const Color(0xFFF96A4C), t)!,
                  Color.lerp(Colors.black87, const Color(0xFFFF8C42), t)!,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Colors.white, // masked by ShaderMask
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
