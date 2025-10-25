import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.enableCaching = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Preload image for better performance
    if (widget.enableCaching && widget.imageUrl.startsWith('http')) {
      _preloadImage();
    }
  }

  Future<void> _preloadImage() async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(widget.imageUrl),
        context,
      );
    } catch (e) {
      // Ignore preload errors
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: _buildImage(),
    );
  }
  
  Widget _buildImage() {
    if (widget.imageUrl.startsWith('assets/')) {
      return Image.asset(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            _isLoading = false;
            return child;
          }
          return AnimatedOpacity(
            opacity: _isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
        cacheWidth: widget.width?.toInt(),
        cacheHeight: widget.height?.toInt(),
      );
    } else if (widget.imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          return _buildErrorWidget();
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: widget.width?.toInt(),
        memCacheHeight: widget.height?.toInt(),
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        useOldImageOnUrlChange: true,
      );
    } else {
      return _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: widget.placeholder ?? const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: widget.errorWidget ?? const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}