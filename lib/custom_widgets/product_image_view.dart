import 'dart:io';

import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter/material.dart';

/// Displays a bundled product image with a runtime local-file fallback.
class ProductImageView extends StatelessWidget {
  /// Creates a product image view.
  const ProductImageView({
    required this.imageName,
    required this.fallbackBuilder,
    this.fit = BoxFit.cover,
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    super.key,
  });

  /// Product image key without extension.
  final String imageName;

  /// How the image should fit inside its layout box.
  final BoxFit fit;

  /// Zoom applied within the clipped image viewport.
  final double scale;

  /// Horizontal framing as a fraction of the viewport width.
  final double offsetX;

  /// Vertical framing as a fraction of the viewport height.
  final double offsetY;

  /// Builds the placeholder when neither bundled nor local image exists.
  final WidgetBuilder fallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final name = imageName.trim();
    if (name.isEmpty || name == 'question') {
      return fallbackBuilder(context);
    }

    return ProductImageFrame(
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
      child: Image.asset(
        'assets/images/$name.png',
        fit: fit,
        errorBuilder:
            (context, exception, stackTrace) => FutureBuilder<File?>(
              future: ProductImageRepository.localImageFile(name),
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file == null) {
                  return fallbackBuilder(context);
                }
                return Image.file(
                  file,
                  fit: fit,
                  errorBuilder:
                      (context, exception, stackTrace) =>
                          fallbackBuilder(context),
                );
              },
            ),
      ),
    );
  }
}

/// Applies the same clipped zoom and positioning to every product image source.
class ProductImageFrame extends StatelessWidget {
  /// Creates a framed product image.
  const ProductImageFrame({
    required this.child,
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    super.key,
  });

  /// Image widget rendered inside the frame.
  final Widget child;

  /// Zoom applied within the frame.
  final double scale;

  /// Horizontal framing as a fraction of the frame width.
  final double offsetX;

  /// Vertical framing as a fraction of the frame height.
  final double offsetY;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final safeScale = scale.clamp(1.0, 3.0);
      final safeX = offsetX.clamp(-0.5, 0.5);
      final safeY = offsetY.clamp(-0.5, 0.5);
      return ClipRect(
        child: Transform.translate(
          offset: Offset(
            safeX * constraints.maxWidth,
            safeY * constraints.maxHeight,
          ),
          child: Transform.scale(scale: safeScale, child: child),
        ),
      );
    },
  );
}
