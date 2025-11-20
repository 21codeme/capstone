import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Lazy loading image widget with caching and placeholder
class LazyImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;
  final Duration placeholderFadeInDuration;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderFadeInDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholderFadeInDuration: placeholderFadeInDuration,
      placeholder: (context, url) => placeholder ?? _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}

/// Circular lazy image for avatars
class LazyCircularImage extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const LazyCircularImage({
    super.key,
    required this.imageUrl,
    this.radius = 24,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorAvatar();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeholder ?? _buildShimmerAvatar(),
          errorWidget: (context, url, error) => errorWidget ?? _buildErrorAvatar(),
          memCacheWidth: (radius * 2).toInt(),
          memCacheHeight: (radius * 2).toInt(),
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildErrorAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      child: Icon(
        Icons.person,
        color: Colors.grey[600],
        size: radius * 0.8,
      ),
    );
  }
}

/// Hero image with lazy loading for detail screens
class LazyHeroImage extends StatelessWidget {
  final String? imageUrl;
  final String heroTag;
  final double? width;
  final double? height;
  final BoxFit fit;
  final VoidCallback? onTap;

  const LazyHeroImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = LazyImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
    );

    if (onTap != null) {
      imageWidget = GestureDetector(
        onTap: onTap,
        child: imageWidget,
      );
    }

    return Hero(
      tag: heroTag,
      child: imageWidget,
    );
  }
}

/// Grid of lazy images with staggered loading
class LazyImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double aspectRatio;
  final double spacing;
  final Function(int index, String url)? onImageTap;

  const LazyImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.aspectRatio = 1.0,
    this.spacing = 8.0,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        aspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onImageTap?.call(index, imageUrls[index]),
          child: LazyImage(
            imageUrl: imageUrls[index],
            borderRadius: BorderRadius.circular(8),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

/// Lazy image with progressive loading
class ProgressiveLazyImage extends StatefulWidget {
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProgressiveLazyImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ProgressiveLazyImage> createState() => _ProgressiveLazyImageState();
}

class _ProgressiveLazyImageState extends State<ProgressiveLazyImage> {
  bool _isFullImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail layer
        if (widget.thumbnailUrl != null)
          LazyImage(
            imageUrl: widget.thumbnailUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            borderRadius: widget.borderRadius,
          ),
        
        // Full image layer
        AnimatedOpacity(
          opacity: _isFullImageLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: LazyImage(
            imageUrl: widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            borderRadius: widget.borderRadius,
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Image carousel with lazy loading
class LazyImageCarousel extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Function(int index)? onPageChanged;

  const LazyImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
        onPageChanged: onPageChanged,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: LazyImage(
              imageUrl: imageUrls[index],
              height: height,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}