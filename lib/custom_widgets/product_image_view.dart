import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ballistics_wallet_flutter/custom_widgets/product_depth_renderer.dart';
import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Displays a bundled product image with a runtime local-file fallback.
class ProductImageView extends StatelessWidget {
  /// Creates a product image view.
  const ProductImageView({
    required this.imageName,
    required this.fallbackBuilder,
    this.fit = BoxFit.contain,
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

/// Opens a GPU-rendered, motion-and-touch depth preview for a product image.
///
/// This deliberately reuses the transparent product cutout. The stage stays
/// fixed while the subject receives parallax occlusion and generated lighting.
class ProductImagePreview extends StatelessWidget {
  /// Creates a tappable product image with a 3D-preview affordance.
  const ProductImagePreview({
    required this.imageName,
    required this.fallbackBuilder,
    this.productName = '',
    this.fit = BoxFit.contain,
    this.scale = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    super.key,
  });

  /// Key used by accessibility and widget tests for the preview launcher.
  static const launcherKey = ValueKey('product-image-preview-launcher');

  /// Key for the perspective-transformed surface in the expanded preview.
  static const previewSurfaceKey = ValueKey('product-image-preview-surface');

  /// Key for the stationary stage behind the transformed subject.
  static const previewBackdropKey = ValueKey('product-image-preview-backdrop');

  /// Product image key without extension.
  final String imageName;

  /// Product name shown in the expanded preview.
  final String productName;

  /// How the source image fits inside its viewport.
  final BoxFit fit;

  /// Saved product-image framing scale.
  final double scale;

  /// Saved horizontal product-image framing.
  final double offsetX;

  /// Saved vertical product-image framing.
  final double offsetY;

  /// Builds the placeholder when neither bundled nor local image exists.
  final WidgetBuilder fallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final trimmedName = productName.trim();
    final semanticLabel =
        trimmedName.isEmpty
            ? 'Open product 3D preview'
            : 'Open $trimmedName 3D preview';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        message: 'Open 3D preview',
        child: GestureDetector(
          key: launcherKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => _openPreview(context),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImageView(
                imageName: imageName,
                fit: fit,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                fallbackBuilder: fallbackBuilder,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar, color: Colors.white, size: 14),
                      SizedBox(width: 3),
                      Text(
                        '3D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder:
        (context) => _ProductDepthPreviewDialog(
          imageName: imageName,
          productName: productName,
          fit: fit,
          imageScale: scale,
          imageOffsetX: offsetX,
          imageOffsetY: offsetY,
          fallbackBuilder: fallbackBuilder,
        ),
  );
}

class _ProductDepthPreviewDialog extends StatefulWidget {
  const _ProductDepthPreviewDialog({
    required this.imageName,
    required this.productName,
    required this.fit,
    required this.imageScale,
    required this.imageOffsetX,
    required this.imageOffsetY,
    required this.fallbackBuilder,
  });

  final String imageName;
  final String productName;
  final BoxFit fit;
  final double imageScale;
  final double imageOffsetX;
  final double imageOffsetY;
  final WidgetBuilder fallbackBuilder;

  @override
  State<_ProductDepthPreviewDialog> createState() =>
      _ProductDepthPreviewDialogState();
}

class _ProductDepthPreviewDialogState
    extends State<_ProductDepthPreviewDialog> {
  static const double _maximumTilt = 0.20;
  static const double _maximumCombinedTilt = 0.24;
  static const double _maximumMotionTilt = 0.075;
  static const double _minimumZoom = 0.9;
  static const double _maximumZoom = 1.35;

  double _tiltX = 0;
  double _tiltY = 0;
  double _motionTiltX = 0;
  double _motionTiltY = 0;
  double _zoom = 1;
  double _zoomAtGestureStart = 1;
  Offset? _motionBaseline;
  // This subscription is cancelled in dispose; the lint cannot follow the
  // lifecycle-owned field through the nullable guard there.
  // ignore: cancel_subscriptions
  StreamSubscription<AccelerometerEvent>? _motionSubscription;

  double get _effectiveTiltX => (_tiltX + _motionTiltX).clamp(
    -_maximumCombinedTilt,
    _maximumCombinedTilt,
  );

  double get _effectiveTiltY => (_tiltY + _motionTiltY).clamp(
    -_maximumCombinedTilt,
    _maximumCombinedTilt,
  );

  @override
  void initState() {
    super.initState();
    _startMotionTracking();
  }

  @override
  void dispose() {
    final motionSubscription = _motionSubscription;
    if (motionSubscription != null) {
      unawaited(motionSubscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth = math.min(mediaQuery.size.width - 32, 560).toDouble();
    final dialogHeight =
        math.min(mediaQuery.size.height * 0.78, 720).toDouble();
    final title = widget.productName.trim();
    final effectiveTiltX = _effectiveTiltX;
    final effectiveTiltY = _effectiveTiltY;

    return Dialog(
      key: const ValueKey('product-image-preview-dialog'),
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: const Color(0xFF201A17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.view_in_ar, color: Color(0xFFFFB56B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.isEmpty ? '3D product preview' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reset view',
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                  ),
                  IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side =
                        math.min(constraints.maxWidth, constraints.maxHeight) *
                        0.88;
                    return Center(
                      child: SizedBox.square(
                        dimension: side,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: _reset,
                          onScaleStart: (_) {
                            _zoomAtGestureStart = _zoom;
                            unawaited(HapticFeedback.selectionClick());
                          },
                          onScaleUpdate:
                              (details) => _updatePerspective(
                                details,
                                Size.square(side),
                              ),
                          onScaleEnd:
                              (_) => unawaited(HapticFeedback.lightImpact()),
                          child: RepaintBoundary(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  const DecoratedBox(
                                    key: ProductImagePreview.previewBackdropKey,
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment(-0.35, -0.45),
                                        radius: 1.25,
                                        colors: [
                                          Color(0xFFFFFCF8),
                                          Color(0xFFF1D8BE),
                                          Color(0xFFC79467),
                                        ],
                                        stops: [0, 0.68, 1],
                                      ),
                                    ),
                                  ),
                                  _buildContactShadow(side),
                                  Padding(
                                    padding: EdgeInsets.all(side * 0.075),
                                    child: Transform.translate(
                                      key:
                                          ProductImagePreview.previewSurfaceKey,
                                      offset: Offset(
                                        effectiveTiltY * 56,
                                        -effectiveTiltX * 50,
                                      ),
                                      child: Transform.scale(
                                        scale: _zoom,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          fit: StackFit.expand,
                                          children: [_buildDepthMaterial()],
                                        ),
                                      ),
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(32),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.48,
                                          ),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.2),
                                            Colors.transparent,
                                            Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                          ],
                                          stops: const [0, 0.32, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Move your iPhone or drag to orbit  •  Pinch to zoom',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactShadow(double side) {
    final horizontalShift = _effectiveTiltY * side * 0.32;
    final widthScale = 1 - (_effectiveTiltX.abs() * 1.1);
    return Align(
      alignment: const Alignment(0, 0.76),
      child: Transform.translate(
        offset: Offset(horizontalShift, _effectiveTiltX * side * 0.09),
        child: Transform.scale(
          scaleX: widthScale,
          child: Container(
            width: side * 0.46,
            height: side * 0.065,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(side),
              color: Colors.black.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepthMaterial() => ProductDepthRenderer(
    imageName: widget.imageName,
    fit: widget.fit,
    scale: widget.imageScale,
    offsetX: widget.imageOffsetX,
    offsetY: widget.imageOffsetY,
    tiltX: _effectiveTiltX / _maximumCombinedTilt,
    tiltY: _effectiveTiltY / _maximumCombinedTilt,
    depthStrength: 1.3,
    fallback: _buildSubject(),
  );

  Widget _buildSubject() => ProductImageView(
    imageName: widget.imageName,
    fit: widget.fit,
    scale: widget.imageScale,
    offsetX: widget.imageOffsetX,
    offsetY: widget.imageOffsetY,
    fallbackBuilder: widget.fallbackBuilder,
  );

  void _startMotionTracking() {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) return;
    _motionSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 8),
    ).listen(
      _updateMotionTilt,
      onError: (Object _, StackTrace _) {},
      cancelOnError: true,
    );
  }

  void _updateMotionTilt(AccelerometerEvent event) {
    final sample = Offset(event.x, event.z);
    final baseline = _motionBaseline;
    if (baseline == null) {
      _motionBaseline = sample;
      return;
    }

    const gravity = 9.80665;
    final targetX = (-((sample.dy - baseline.dy) / gravity) * 0.22).clamp(
      -_maximumMotionTilt,
      _maximumMotionTilt,
    );
    final targetY = (((sample.dx - baseline.dx) / gravity) * 0.22).clamp(
      -_maximumMotionTilt,
      _maximumMotionTilt,
    );
    final nextX = ui.lerpDouble(_motionTiltX, targetX, 0.16)!;
    final nextY = ui.lerpDouble(_motionTiltY, targetY, 0.16)!;
    if ((nextX - _motionTiltX).abs() < 0.00025 &&
        (nextY - _motionTiltY).abs() < 0.00025) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _motionTiltX = nextX;
      _motionTiltY = nextY;
    });
  }

  void _updatePerspective(ScaleUpdateDetails details, Size size) {
    final normalizedX = ((details.localFocalPoint.dx / size.width) - 0.5) * 2;
    final normalizedY = ((details.localFocalPoint.dy / size.height) - 0.5) * 2;
    setState(() {
      _tiltX = (-normalizedY * _maximumTilt).clamp(-_maximumTilt, _maximumTilt);
      _tiltY = (normalizedX * _maximumTilt).clamp(-_maximumTilt, _maximumTilt);
      _zoom = (_zoomAtGestureStart * details.scale).clamp(
        _minimumZoom,
        _maximumZoom,
      );
    });
  }

  void _reset() {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _motionTiltX = 0;
      _motionTiltY = 0;
      _motionBaseline = null;
      _zoom = 1;
      _zoomAtGestureStart = 1;
    });
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

  /// Lowest scale available in the image-framing controls.
  static const double minScale = 0.7;

  /// Largest scale available in the image-framing controls.
  static const double maxScale = 3;

  /// Centered starting scale for a newly selected image.
  ///
  /// This leaves roughly 10% clearance on every side of a contained image so
  /// edge-to-edge product photos are not clipped before the user adjusts them.
  static const double initialFittedScale = 0.8;

  /// Furthest an image can be shifted, as a fraction of the viewport.
  static const double maxOffset = 0.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final safeScale = scale.clamp(minScale, maxScale);
      final safeX = offsetX.clamp(-maxOffset, maxOffset);
      final safeY = offsetY.clamp(-maxOffset, maxOffset);
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
