// lib/core/services/image_cache_manager.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for product images with optimized settings
class ProductImageCacheManager {
  static const String key = 'productImageCache';
  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 7), // Images cached for 7 days
        maxNrOfCacheObjects: 200, // Maximum 200 images in cache
        repo: JsonCacheInfoRepository(databaseName: key),
        fileSystem: IOFileSystem(key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Clear specific image from cache
  static Future<void> removeFile(String url) async {
    await instance.removeFile(url);
  }

  /// Get cache info (size, file count)
  static Future<Map<String, dynamic>> getCacheInfo() async {
    // This is an approximation since the package doesn't provide exact size
    final files = await instance.getFileFromCache(key);
    return {
      'cached': files != null,
      'message': files != null ? 'Cache active' : 'No cache data'
    };
  }
}

/// Optimized image widget for product images with caching
class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedProductImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: ProductImageCacheManager.instance,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: backgroundColor ?? Colors.grey[200],
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey[400]!,
                    ),
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        memCacheWidth: width != null ? (width! * 2).toInt() : null,
        memCacheHeight: height != null ? (height! * 2).toInt() : null,
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }
}

/// Optimized thumbnail image for lists and grids
class CachedProductThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BoxFit fit;

  const CachedProductThumbnail({
    Key? key,
    required this.imageUrl,
    this.size = 100,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedProductImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

/// Preload images for better UX
class ImagePreloader {
  /// Preload a single image
  static Future<void> preloadImage(
    BuildContext context,
    String imageUrl,
  ) async {
    if (imageUrl.isEmpty) return;

    try {
      await precacheImage(
        CachedNetworkImageProvider(
          imageUrl,
          cacheManager: ProductImageCacheManager.instance,
        ),
        context,
      );
    } catch (e) {
      print('Error preloading image: $e');
    }
  }

  /// Preload multiple images
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    final futures = imageUrls
        .where((url) => url.isNotEmpty)
        .map((url) => preloadImage(context, url))
        .toList();

    await Future.wait(futures);
  }
}