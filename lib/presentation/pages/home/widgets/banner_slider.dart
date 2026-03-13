// lib/presentation/pages/home/widgets/banner_slider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import '../../../../config/theme.dart';

// ── Model ──────────────────────────────────────────────────────────────────────
class _HeroSlide {
  final String image;
  final int displayOrder;

  const _HeroSlide({required this.image, required this.displayOrder});

  factory _HeroSlide.fromJson(Map<String, dynamic> json) => _HeroSlide(
        image: json['image'] as String,
        displayOrder: json['display_order'] as int? ?? 0,
      );
}

// ── Widget ─────────────────────────────────────────────────────────────────────
class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  static const _baseUrl = 'https://anugami.com/api/v1';

  int _currentIndex = 0;
  List<_HeroSlide> _slides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSlides();
  }

  Future<void> _fetchSlides() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/system-settings/hero-slides/public/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final slides = data
            .map((e) => _HeroSlide.fromJson(e as Map<String, dynamic>))
            .where((s) {
          final raw = (data.firstWhere(
            (e) => e['image'] == s.image,
            orElse: () => {},
          ) as Map<String, dynamic>);
          return (raw['is_active'] as bool? ?? false) && s.image.isNotEmpty;
        }).toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        setState(() {
          _slides = slides;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load banners';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load banners';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildShimmer();
    if (_error != null || _slides.isEmpty) return _buildFallback();
    return _buildSlider();
  }

  // ── Slider ─────────────────────────────────────────────────────────────────
  Widget _buildSlider() {
    return Column(
      children: [
        // ✅ Aspect ratio 3.4:1 (1430×425) — responsive to screen width
        AspectRatio(
          aspectRatio: 1430 / 425,
          child: CarouselSlider(
            options: CarouselOptions(
              height:
                  double.infinity, // height controlled by AspectRatio parent
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 600),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: (index, _) =>
                  setState(() => _currentIndex = index),
            ),
            items: _slides.map((slide) {
              return SizedBox(
                width: double.infinity,
                child: Image.network(
                  slide.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _buildShimmerBox();
                  },
                  errorBuilder: (context, error, stack) => _buildErrorBox(),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _slides.asMap().entries.map((entry) {
            final isActive = _currentIndex == entry.key;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 20.0 : 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? AppTheme.primaryColor
                    : Colors.grey.withOpacity(0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Shimmer loading ────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1430 / 425,
          child: _ShimmerBox(width: double.infinity, height: double.infinity),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox({double height = 330}) {
    return _ShimmerBox(
      width: double.infinity,
      height: height,
    );
  }

  // ── Error / empty fallback ─────────────────────────────────────────────────
  Widget _buildFallback() {
    return AspectRatio(
      aspectRatio: 1430 / 425,
      child: Container(
        width: double.infinity,
        color: Colors.grey[100],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetchSlides();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 48, color: Colors.grey[400]),
      ),
    );
  }
}

// ── Shimmer box widget ─────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}
