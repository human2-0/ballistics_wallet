import 'package:ballistics_wallet_flutter/custom_widgets/product_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
