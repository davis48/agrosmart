import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agriculture/core/widgets/skeleton_loaders.dart';

/// Lazy loading image with placeholder and error handling
/// Optimized for galleries and grids
class LazyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticsLabel;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.semanticsLabel,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ?? (isDark ? Colors.grey[800] : Colors.grey[200]);

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Container(
              width: width,
              height: height,
              color: bgColor,
              child: SkeletonContainer(
                width: width ?? double.infinity,
                height: height ?? 100,
                borderRadius: borderRadius,
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: bgColor,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  size: 32,
                ),
              ),
            ),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

/// Gallery grid with lazy loading
class LazyImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;
  final BorderRadius imageBorderRadius;
  final void Function(int index)? onImageTap;
  final ScrollController? scrollController;

  const LazyImageGallery({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(8),
    this.imageBorderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onImageTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: onImageTap != null ? () => onImageTap!(index) : null,
          child: Hero(
            tag: 'gallery_image_$index',
            child: LazyImage(
              imageUrl: imageUrls[index],
              borderRadius: imageBorderRadius,
              semanticsLabel: 'Image ${index + 1} sur ${imageUrls.length}',
            ),
          ),
        );
      },
    );
  }
}

/// Full screen image viewer with zoom and swipe
class LazyImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final Color backgroundColor;
  final bool showIndicator;

  const LazyImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.backgroundColor = Colors.black,
    this.showIndicator = true,
  });

  @override
  State<LazyImageViewer> createState() => _LazyImageViewerState();
}

class _LazyImageViewerState extends State<LazyImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: widget.showIndicator
            ? Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: 'gallery_image_$index',
                    child: LazyImage(
                      imageUrl: widget.imageUrls[index],
                      fit: BoxFit.contain,
                      semanticsLabel:
                          'Image ${index + 1} sur ${widget.imageUrls.length}',
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.showIndicator && widget.imageUrls.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thumbnail with lazy loading and tap to expand
class LazyThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BorderRadius borderRadius;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  final bool showExpandIcon;

  const LazyThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 80,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.semanticsLabel,
    this.onTap,
    this.showExpandIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          LazyImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            borderRadius: borderRadius,
            semanticsLabel: semanticsLabel,
          ),
          if (showExpandIcon)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Progress indicator overlay for lazy images
class LazyImageWithProgress extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticsLabel;

  const LazyImageWithProgress({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        progressIndicatorBuilder: (context, url, progress) => Container(
          width: width,
          height: height,
          color: bgColor,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.progress,
              color: Theme.of(context).primaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: bgColor,
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 32),
          ),
        ),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      ),
    );
  }
}
