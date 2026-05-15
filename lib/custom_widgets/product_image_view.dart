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
    super.key,
  });

  /// Product image key without extension.
  final String imageName;

  /// How the image should fit inside its layout box.
  final BoxFit fit;

  /// Builds the placeholder when neither bundled nor local image exists.
  final WidgetBuilder fallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final name = imageName.trim();
    if (name.isEmpty || name == 'question') {
      return fallbackBuilder(context);
    }

    return Image.asset(
      'assets/images/$name.png',
      fit: fit,
      errorBuilder: (context, exception, stackTrace) {
        return FutureBuilder<File?>(
          future: ProductImageRepository.localImageFile(name),
          builder: (context, snapshot) {
            final file = snapshot.data;
            if (file == null) {
              return fallbackBuilder(context);
            }
            return Image.file(
              file,
              fit: fit,
              errorBuilder: (context, exception, stackTrace) {
                return fallbackBuilder(context);
              },
            );
          },
        );
      },
    );
  }
}
