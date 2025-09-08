import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/cache/cache_interfaces.dart';

/// Widget para exibir imagens com cache automático
class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final ImageSize? cacheSize;
  final bool forceRefresh;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheSize,
    this.forceRefresh = false,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  ImageCacheResult? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.forceRefresh != widget.forceRefresh) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final imageService = context.read<ImageCacheService>();
      final result = await imageService.getImage(
        widget.imageUrl,
        size: widget.cacheSize,
        forceRefresh: widget.forceRefresh,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          _error = result.hasError ? result.error.toString() : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = _buildPlaceholder();
    } else if (_error != null || !(_result?.hasLocalFile ?? false)) {
      child = _buildErrorWidget();
    } else {
      child = _buildImage();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius,
      ),
      clipBehavior: widget.borderRadius != null ? Clip.antiAlias : Clip.none,
      child: child,
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Image.file(
      File(_result!.localPath!),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget();
      },
    );
  }
}

/// Widget para avatar circular com cache
class CachedAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const CachedAvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildDefaultAvatar();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      child: ClipOval(
        child: CachedImageWidget(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheSize: ImageSize.thumbnail,
          placeholder: placeholder ?? _buildDefaultAvatar(),
          errorWidget: errorWidget ?? _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius * 0.8,
        color: Colors.grey[600],
      ),
    );
  }
}

/// Widget para galeria de imagens com cache
class CachedImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double itemHeight;
  final double itemSpacing;
  final int maxItems;
  final VoidCallback? onViewAll;

  const CachedImageGallery({
    super.key,
    required this.imageUrls,
    this.itemHeight = 120,
    this.itemSpacing = 8,
    this.maxItems = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayUrls = imageUrls.take(maxItems).toList();
    final hasMore = imageUrls.length > maxItems;

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayUrls.length + (hasMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
        itemBuilder: (context, index) {
          if (index == displayUrls.length) {
            // Botão "Ver mais"
            return _buildViewMoreButton(context);
          }

          return _buildImageItem(displayUrls[index]);
        },
      ),
    );
  }

  Widget _buildImageItem(String imageUrl) {
    return AspectRatio(
      aspectRatio: 1,
      child: CachedImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        cacheSize: ImageSize.medium,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildViewMoreButton(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.grey[600],
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '+${imageUrls.length - maxItems}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}