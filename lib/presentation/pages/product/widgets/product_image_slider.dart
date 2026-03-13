import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/product_model.dart';
import 'package:anu_app/presentation/widgets/logo_loader.dart';

/// ---------------------------
/// Slider Item Wrapper
/// ---------------------------
enum SliderItemType { image, video }

class SliderItem {
  final SliderItemType type;
  final ImageModel? image;
  final VideoModel? video;

  SliderItem.image(this.image)
      : type = SliderItemType.image,
        video = null;

  SliderItem.video(this.video)
      : type = SliderItemType.video,
        image = null;
}

/// ---------------------------
/// Product Image + Video Slider (OPTIMIZED - NO THUMBNAIL)
/// ---------------------------
class ProductImageSlider extends StatefulWidget {
  final List<ImageModel> images;
  final List<VideoModel> videos;

  const ProductImageSlider({
    Key? key,
    required this.images,
    required this.videos,
  }) : super(key: key);

  @override
  State<ProductImageSlider> createState() => _ProductImageSliderState();
}

class _ProductImageSliderState extends State<ProductImageSlider> {
  int _currentIndex = 0;

  final CarouselSliderController _carouselController =
      CarouselSliderController();

  late List<SliderItem> _items;

  // ✅ Cache for video controllers (avoid re-creating)
  final Map<int, VideoPlayerController> _videoControllers = {};

  // ✅ Track which videos are currently playing
  final Map<int, bool> _isVideoPlaying = {};

  // ✅ Track video initialization state
  final Map<int, bool> _isVideoInitialized = {};

  // ✅ Track video loading state
  final Map<int, bool> _isVideoLoading = {};

  /// ---------------------------
  /// INIT
  /// ---------------------------
  @override
  void initState() {
    super.initState();
    _buildItems();
  }

  /// ---------------------------
  /// BUILD ITEMS FROM PROPS
  /// ---------------------------
  void _buildItems() {
    _items = [];

    // Preserve API order (images first, videos as received)
    for (final img in widget.images) {
      _items.add(SliderItem.image(img));
    }

    for (final vid in widget.videos) {
      _items.add(SliderItem.video(vid));
    }
  }

  /// ---------------------------
  /// HANDLE PROP CHANGES (FIX FOR VARIANT IMAGE UPDATE)
  /// ---------------------------
  @override
  void didUpdateWidget(ProductImageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Check if images changed (for variant selection)
    if (widget.images != oldWidget.images) {
      // Dispose old video controllers
      for (final controller in _videoControllers.values) {
        controller.dispose();
      }
      _videoControllers.clear();
      _isVideoPlaying.clear();
      _isVideoInitialized.clear();
      _isVideoLoading.clear();

      // Rebuild items
      setState(() {
        _buildItems();
        _currentIndex = 0; // Reset to first image
      });
    }
  }

  /// ---------------------------
  /// DISPOSE
  /// ---------------------------
  @override
  void dispose() {
    // ✅ Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  /// ---------------------------
  /// PAGE CHANGE HANDLER
  /// ---------------------------
  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);

    final item = _items[index];

    // ✅ Pause all other videos
    for (final entry in _videoControllers.entries) {
      if (entry.key != index) {
        entry.value.pause();
        _isVideoPlaying[entry.key] = false;
      }
    }

    // ✅ If current item is video, initialize it (but don't auto-play)
    if (item.type == SliderItemType.video) {
      _initializeVideoIfNeeded(index);
    }
  }

  /// ---------------------------
  /// INITIALIZE VIDEO (LAZY)
  /// ---------------------------
  Future<void> _initializeVideoIfNeeded(int index) async {
    // ✅ Already initialized? Skip
    if (_isVideoInitialized[index] == true) {
      return;
    }

    final item = _items[index];
    if (item.type != SliderItemType.video) return;

    setState(() {
      _isVideoLoading[index] = true;
    });

    try {
      // ✅ Create controller if not exists
      if (!_videoControllers.containsKey(index)) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(item.video!.videoUrl),
        );

        _videoControllers[index] = controller;

        // ✅ Initialize in background
        await controller.initialize();

        if (mounted) {
          setState(() {
            _isVideoInitialized[index] = true;
            _isVideoPlaying[index] = false;
            _isVideoLoading[index] = false;
          });
        }
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized[index] = false;
          _isVideoLoading[index] = false;
        });
      }
    }
  }

  /// ---------------------------
  /// TOGGLE VIDEO PLAY/PAUSE
  /// ---------------------------
  void _toggleVideoPlayback(int index) {
    final controller = _videoControllers[index];
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (_isVideoPlaying[index] == true) {
        controller.pause();
        _isVideoPlaying[index] = false;
      } else {
        controller.play();
        _isVideoPlaying[index] = true;
      }
    });
  }

  /// ---------------------------
  /// UI
  /// ---------------------------
  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        /// ---------------------------
        /// MAIN SLIDER
        /// ---------------------------
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            aspectRatio: 1,
            viewportFraction: 1,
            enableInfiniteScroll: _items.length > 1,
            onPageChanged: (index, reason) => _onPageChanged(index),
          ),
          items: _items
              .asMap()
              .entries
              .map((entry) => _buildSliderItem(entry.key, entry.value))
              .toList(),
        ),

        const SizedBox(height: 16),

        /// ---------------------------
        /// DOT INDICATORS
        /// ---------------------------
        if (_items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _items.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? const Color(0xFFFEAF4E)
                      : Colors.grey.withOpacity(0.5),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),

        /// ---------------------------
        /// THUMBNAILS
        /// ---------------------------
        if (_items.length > 1)
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];

                return GestureDetector(
                  onTap: () {
                    _carouselController.animateToPage(index);
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index
                            ? const Color(0xFFFEAF4E)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: item.type == SliderItemType.video
                          ? Container(
                              color: Colors.grey.shade200,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 28,
                                    color: Colors.grey.shade600,
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.network(
                              item.image!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// ---------------------------
  /// SLIDER ITEM BUILDER
  /// ---------------------------
  Widget _buildSliderItem(int index, SliderItem item) {
    if (item.type == SliderItemType.video) {
      return _buildVideoItem(index, item.video!);
    }

    return _buildImageItem(item.image!);
  }

  /// ---------------------------
  /// BUILD VIDEO ITEM (OPTIMIZED - NO THUMBNAIL)
  /// ---------------------------
  Widget _buildVideoItem(int index, VideoModel video) {
    final controller = _videoControllers[index];
    final isInitialized = _isVideoInitialized[index] == true;
    final isPlaying = _isVideoPlaying[index] == true;
    final isLoading = _isVideoLoading[index] == true;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ Show video placeholder when not initialized or paused
            if (!isInitialized || !isPlaying)
              Container(
                color: Colors.grey.shade900,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),

            // ✅ Show video player when initialized and playing
            if (isInitialized && controller != null)
              if (isPlaying)
                VideoPlayer(controller)
              else
                const SizedBox.shrink(),

            // ✅ Loading indicator
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LogoLoader(),
                      SizedBox(height: 12),
                      Text(
                        'Loading video...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ Play/Pause Button Overlay
            if (isInitialized && !isLoading)
              GestureDetector(
                onTap: () => _toggleVideoPlayback(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ "Tap to load video" hint (when not initialized and not loading)
            if (!isInitialized && !isLoading && _currentIndex == index)
              Positioned(
                bottom: 16,
                child: GestureDetector(
                  onTap: () => _initializeVideoIfNeeded(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEAF4E),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tap to play video',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ✅ Video title overlay (top)
            if (video.title.isNotEmpty && !isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // ✅ Video controls (when playing)
            if (isPlaying && controller != null && !isLoading)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final position = value.position;
                      final duration = value.duration;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFEAF4E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Time display
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ---------------------------
  /// BUILD IMAGE ITEM
  /// ---------------------------
  Widget _buildImageItem(ImageModel image) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, image.imageUrl),
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
        child: Image.network(
          image.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: LogoLoader());
          },
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  /// ---------------------------
  /// FULLSCREEN IMAGE GALLERY (FIXED ZOOM + SWIPE)
  /// ---------------------------
  void _showFullScreenImage(BuildContext context, String initialImageUrl) {
    // Find initial index
    int initialIndex = 0;
    final imageItems =
        _items.where((item) => item.type == SliderItemType.image).toList();

    for (int i = 0; i < imageItems.length; i++) {
      if (imageItems[i].image?.imageUrl == initialImageUrl) {
        initialIndex = i;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImageGallery(
          images: imageItems.map((item) => item.image!.imageUrl).toList(),
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// ---------------------------
  /// FORMAT DURATION
  /// ---------------------------
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// ---------------------------
/// FULLSCREEN IMAGE GALLERY WIDGET
/// ---------------------------
class _FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  // Track zoom level for each image
  final Map<int, TransformationController> _transformControllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Initialize transform controllers for each image
    for (int i = 0; i < widget.images.length; i++) {
      _transformControllers[i] = TransformationController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ PageView for swiping between images
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return _buildZoomableImage(index);
            },
          ),

          // ✅ Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.6),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ✅ Image counter (1/5, 2/5, etc.)
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ✅ Dot indicators at bottom
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? const Color(0xFFFEAF4E)
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ Build zoomable image with InteractiveViewer
  Widget _buildZoomableImage(int index) {
    return InteractiveViewer(
      transformationController: _transformControllers[index],
      panEnabled: true,
      scaleEnabled: true,
      minScale: 0.5, // ✅ Can zoom out to 50%
      maxScale: 4.0, // ✅ Can zoom in to 400%
      boundaryMargin: const EdgeInsets.all(20),
      onInteractionEnd: (details) {
        // ✅ Reset to original size on double tap
        final controller = _transformControllers[index]!;
        if (controller.value.getMaxScaleOnAxis() == 1.0) {
          // Already at original size, do nothing
        }
      },
      child: Center(
        child: Image.network(
          widget.images[index],
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: LogoLoader());
          },
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
