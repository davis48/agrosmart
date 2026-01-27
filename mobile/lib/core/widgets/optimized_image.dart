/// Service d'optimisation des images
/// AgriSmart CI - Application Mobile
///
/// Fonctionnalités:
/// - Lazy loading d'images
/// - Mise en cache des images
/// - Compression automatique
/// - Placeholder pendant le chargement
/// - Gestion des erreurs de chargement
library;

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Service de gestion optimisée des images
class OptimizedImageService {
  static final OptimizedImageService _instance =
      OptimizedImageService._internal();
  factory OptimizedImageService() => _instance;
  OptimizedImageService._internal();

  /// Configuration du cache
  static const int maxCacheWidth = 800;
  static const int maxCacheHeight = 800;
  static const int memoryCacheSize = 100; // Nombre d'images en mémoire

  /// URL de base pour les images
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Construire l'URL d'une image avec paramètres de taille
  String getOptimizedUrl(
    String imagePath, {
    int? width,
    int? height,
    int? quality,
  }) {
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    final params = <String, String>{};
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    if (quality != null) params['q'] = quality.toString();

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$baseUrl/uploads/$imagePath${queryString.isNotEmpty ? '?$queryString' : ''}';
  }

  /// Précharger une liste d'images
  Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (e) {
        developer.log(
          '[ImageService] Failed to precache image: $url',
          name: 'Images',
          error: e,
        );
      }
    }
  }
}

/// Widget d'image optimisé avec lazy loading
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final bool fadeIn;
  final Duration fadeInDuration;
  final Color? backgroundColor;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeIn = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final service = OptimizedImageService();
    final optimizedUrl = service.getOptimizedUrl(
      imageUrl,
      width: memCacheWidth ?? width?.toInt(),
      height: memCacheHeight ?? height?.toInt(),
    );

    Widget image = CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? OptimizedImageService.maxCacheWidth,
      memCacheHeight: memCacheHeight ?? OptimizedImageService.maxCacheHeight,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(context),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context),
      fadeInDuration: fadeIn ? fadeInDuration : Duration.zero,
      fadeOutDuration: Duration.zero,
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: image,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(width: width, height: height, color: Colors.white),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey[400],
            size: (width ?? 100) * 0.3,
          ),
          if ((height ?? 100) > 80)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Image non disponible',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget Avatar optimisé
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        child: ClipOval(
          child: OptimizedImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            memCacheWidth: (radius * 2 * 2).toInt(), // 2x pour haute résolution
            memCacheHeight: (radius * 2 * 2).toInt(),
            placeholder: _buildInitials(context),
            errorWidget: _buildInitials(context),
          ),
        ),
      );
    }

    return _buildInitials(context);
  }

  Widget _buildInitials(BuildContext context) {
    final initials = _getInitials();
    final bgColor = backgroundColor ?? _getColorFromName();

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style:
            textStyle ??
            TextStyle(
              color: Colors.white,
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  Color _getColorFromName() {
    if (name == null || name!.isEmpty) return Colors.grey;

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];

    final hash = name!.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }
}

/// Widget Image de parcelle avec indicateur de santé
class ParcelleImageCard extends StatelessWidget {
  final String? imageUrl;
  final String parcelleName;
  final String? healthStatus;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const ParcelleImageCard({
    super.key,
    this.imageUrl,
    required this.parcelleName,
    this.healthStatus,
    this.width = double.infinity,
    this.height = 180,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image de fond
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? OptimizedImage(
                      imageUrl: imageUrl!,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                    )
                  : _buildPlaceholderImage(),
            ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Indicateur de santé
            if (healthStatus != null)
              Positioned(top: 8, right: 8, child: _buildHealthIndicator()),

            // Nom de la parcelle
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                parcelleName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: width,
      height: height,
      color: Colors.green[100],
      child: Icon(
        Icons.landscape_outlined,
        size: height * 0.3,
        color: Colors.green[300],
      ),
    );
  }

  Widget _buildHealthIndicator() {
    Color color;
    IconData icon;

    switch (healthStatus?.toUpperCase()) {
      case 'OPTIMAL':
        color = Colors.green;
        icon = Icons.check_circle;
      case 'SURVEILLANCE':
        color = Colors.orange;
        icon = Icons.warning_amber;
      case 'CRITIQUE':
        color = Colors.red;
        icon = Icons.error;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            healthStatus!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Image de diagnostic
class DiagnosticImageCard extends StatelessWidget {
  final String imageUrl;
  final String? diseaseName;
  final double? confidenceScore;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const DiagnosticImageCard({
    super.key,
    required this.imageUrl,
    this.diseaseName,
    this.confidenceScore,
    this.width = double.infinity,
    this.height = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getBorderColor(), width: 2),
        ),
        child: Stack(
          children: [
            // Image du diagnostic
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: OptimizedImage(
                imageUrl: imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
              ),
            ),

            // Badge maladie détectée
            if (diseaseName != null && diseaseName!.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.coronavirus_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          diseaseName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Score de confiance
            if (confidenceScore != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(confidenceScore! * 100).toInt()}% sûr',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (diseaseName != null && diseaseName!.isNotEmpty) {
      return Colors.red.withValues(alpha: 0.5);
    }
    return Colors.green.withValues(alpha: 0.5);
  }
}

/// Widget Galerie d'images avec lazy loading
class LazyImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final void Function(int index)? onImageTap;
  final ScrollController? scrollController;

  const LazyImageGallery({
    super.key,
    required this.imageUrls,
    this.itemWidth = 120,
    this.itemHeight = 120,
    this.spacing = 8,
    this.onImageTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 16 : spacing / 2,
              right: index == imageUrls.length - 1 ? 16 : spacing / 2,
            ),
            child: GestureDetector(
              onTap: () => onImageTap?.call(index),
              child: OptimizedImage(
                imageUrl: imageUrls[index],
                width: itemWidth,
                height: itemHeight,
                borderRadius: BorderRadius.circular(8),
                memCacheWidth: itemWidth.toInt() * 2,
                memCacheHeight: itemHeight.toInt() * 2,
              ),
            ),
          );
        },
      ),
    );
  }
}
