import 'package:ballistics_wallet_flutter/custom_widgets/product_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProductImageView contains the complete source image by default', () {
    final view = ProductImageView(
      imageName: 'test',
      fallbackBuilder: (_) => const SizedBox.shrink(),
    );

    expect(view.fit, BoxFit.contain);
  });

  testWidgets(
    'ProductImageFrame applies matching scale and fractional offset',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 200,
              child: ProductImageFrame(
                scale: 2,
                offsetX: 0.2,
                offsetY: -0.1,
                child: ColoredBox(color: Colors.orange),
              ),
            ),
          ),
        ),
      );

      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      expect(transforms, hasLength(2));

      final translation = transforms.first.transform.storage;
      expect(translation[12], 40);
      expect(translation[13], -20);

      final scale = transforms.last.transform.storage;
      expect(scale[0], 2);
      expect(scale[5], 2);
    },
  );

  testWidgets('ProductImageFrame permits zooming out by 30%', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox.square(
          dimension: 200,
          child: ProductImageFrame(
            scale: ProductImageFrame.minScale,
            child: ColoredBox(color: Colors.orange),
          ),
        ),
      ),
    );

    final transforms = tester.widgetList<Transform>(find.byType(Transform));
    final scale = transforms.last.transform.storage;
    expect(scale[0], ProductImageFrame.minScale);
    expect(scale[5], ProductImageFrame.minScale);
  });

  test('new images start contained with clearance for adjustment', () {
    expect(ProductImageFrame.initialFittedScale, 0.8);
    expect(ProductImageFrame.initialFittedScale, lessThan(1));
  });

  testWidgets('tapping a product image opens the lightweight 3D preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.square(
            dimension: 200,
            child: ProductImagePreview(
              imageName: 'question',
              productName: 'Intergalactic',
              fallbackBuilder: (_) => const ColoredBox(color: Colors.orange),
            ),
          ),
        ),
      ),
    );

    expect(find.text('3D'), findsOneWidget);
    await tester.tap(find.byKey(ProductImagePreview.launcherKey));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('product-image-preview-dialog')),
      findsOneWidget,
    );
    expect(find.text('Intergalactic'), findsOneWidget);
    expect(
      find.text('Move your iPhone or drag to orbit  •  Pinch to zoom'),
      findsOneWidget,
    );
  });

  testWidgets('keeps the preview backdrop outside the transformed subject', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 200,
          child: ProductImagePreview(
            imageName: 'question',
            fallbackBuilder: (_) => const ColoredBox(color: Colors.orange),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ProductImagePreview.launcherKey));
    await tester.pumpAndSettle();

    final transformedSubject = find.byKey(
      ProductImagePreview.previewSurfaceKey,
    );
    final stationaryBackdrop = find.byKey(
      ProductImagePreview.previewBackdropKey,
    );
    expect(transformedSubject, findsOneWidget);
    expect(stationaryBackdrop, findsOneWidget);
    expect(
      find.descendant(of: transformedSubject, matching: stationaryBackdrop),
      findsNothing,
    );
  });

  testWidgets('dragging the preview changes its perspective transform', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 200,
          child: ProductImagePreview(
            imageName: 'question',
            fallbackBuilder: (_) => const ColoredBox(color: Colors.orange),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(ProductImagePreview.launcherKey));
    await tester.pumpAndSettle();

    final before =
        tester
            .widget<Transform>(
              find.byKey(ProductImagePreview.previewSurfaceKey),
            )
            .transform
            .storage
            .toList();
    await tester.drag(
      find.byKey(ProductImagePreview.previewSurfaceKey),
      const Offset(50, 30),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final after =
        tester
            .widget<Transform>(
              find.byKey(ProductImagePreview.previewSurfaceKey),
            )
            .transform
            .storage
            .toList();

    expect(after, isNot(before));
  });
}
