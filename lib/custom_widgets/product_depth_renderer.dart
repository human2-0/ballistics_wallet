import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// GPU-rendered pseudo-volume for a transparent product cutout.
///
/// The material derives a height field from alpha, broad volume, and image
/// luminance. A fragment shader then applies parallax occlusion, generated
/// normals, directional lighting, rim light, and specular response.
class ProductDepthRenderer extends StatefulWidget {
  /// Creates an alpha-aware GPU depth material.
  const ProductDepthRenderer({
    required this.imageName,
    required this.fallback,
    required this.tiltX,
    required this.tiltY,
    this.fit = BoxFit.contain,
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.depthStrength = 1,
    super.key,
  });

  /// Product image key without extension.
  final String imageName;

  /// Widget shown while the shader loads or if GPU rendering is unavailable.
  final Widget fallback;

  /// Vertical viewing angle normalized to the preview's tilt range.
  final double tiltX;

  /// Horizontal viewing angle normalized to the preview's tilt range.
  final double tiltY;

  /// How the source image fits inside its viewport.
  final BoxFit fit;

  /// Saved product-image framing scale.
  final double scale;

  /// Saved horizontal product-image framing.
  final double offsetX;

  /// Saved vertical product-image framing.
  final double offsetY;

  /// Strength of the height-field displacement.
  final double depthStrength;

  static Future<ui.FragmentProgram>? _program;

  /// Starts loading the compiled depth program before a preview is painted.
  static Future<ui.FragmentProgram> prewarm() =>
      _program ??= ui.FragmentProgram.fromAsset(
        'shaders/product_depth_material.frag',
      );

  @override
  State<ProductDepthRenderer> createState() => _ProductDepthRendererState();
}

class _ProductDepthRendererState extends State<ProductDepthRenderer> {
  ui.Image? _image;
  ui.FragmentShader? _shader;
  bool _failed = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant ProductDepthRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageName != widget.imageName) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    _shader?.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    _failed = false;
    try {
      final results = await Future.wait<Object>([
        ProductDepthRenderer.prewarm(),
        _decodeProductImage(widget.imageName),
      ]);
      if (!mounted || generation != _loadGeneration) {
        (results[1] as ui.Image).dispose();
        return;
      }

      _shader?.dispose();
      _image?.dispose();
      setState(() {
        _image = results[1] as ui.Image;
        _shader = (results[0] as ui.FragmentProgram).fragmentShader();
      });
    } on Object catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final shader = _shader;
    if (_failed || image == null || shader == null) {
      return widget.fallback;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeScale = widget.scale.clamp(0.7, 3.0);
        final safeX = widget.offsetX.clamp(-0.5, 0.5);
        final safeY = widget.offsetY.clamp(-0.5, 0.5);
        return Transform.translate(
          offset: Offset(
            safeX * constraints.maxWidth,
            safeY * constraints.maxHeight,
          ),
          child: Transform.scale(
            scale: safeScale,
            child: CustomPaint(
              painter: _ProductDepthPainter(
                image: image,
                shader: shader,
                fit: widget.fit,
                tiltX: widget.tiltX,
                tiltY: widget.tiltY,
                depthStrength: widget.depthStrength,
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<ui.Image> _decodeProductImage(String imageName) async {
  final name = imageName.trim();
  if (name.isEmpty || name == 'question') {
    throw ArgumentError.value(imageName, 'imageName', 'No product image');
  }

  Uint8List bytes;
  try {
    final data = await rootBundle.load('assets/images/$name.png');
    bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } on Object catch (_) {
    final file = await ProductImageRepository.localImageFile(name);
    if (file == null || !file.existsSync()) {
      throw StateError('Product image is unavailable');
    }
    bytes = File(file.path).readAsBytesSync();
  }

  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

class _ProductDepthPainter extends CustomPainter {
  const _ProductDepthPainter({
    required this.image,
    required this.shader,
    required this.fit,
    required this.tiltX,
    required this.tiltY,
    required this.depthStrength,
  });

  final ui.Image image;
  final ui.FragmentShader shader;
  final BoxFit fit;
  final double tiltX;
  final double tiltY;
  final double depthStrength;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, image.width.toDouble())
      ..setFloat(3, image.height.toDouble())
      ..setFloat(4, tiltX.clamp(-1, 1))
      ..setFloat(5, tiltY.clamp(-1, 1))
      ..setFloat(6, depthStrength.clamp(0.4, 1.6))
      ..setFloat(7, fit == BoxFit.cover ? 1 : 0)
      ..setImageSampler(0, image, filterQuality: FilterQuality.high);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ProductDepthPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.shader != shader ||
      oldDelegate.fit != fit ||
      oldDelegate.tiltX != tiltX ||
      oldDelegate.tiltY != tiltY ||
      oldDelegate.depthStrength != depthStrength;
}
