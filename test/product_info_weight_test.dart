import 'package:ballistics_wallet_flutter/custom_widgets/product_weight_summary.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductInfo weight calculation', () {
    test('sums powder and citric grams for every pressing', () {
      final product = ProductInfo(
        productName: 'Minion',
        target: 100,
        imageName: 'minion',
        product: const [
          Pressing('Yellow', 71.88, 23.96),
          Pressing('Blue', 83, 27.67),
        ],
      );

      expect(product.powderWeightGrams, closeTo(154.88, 0.001));
      expect(product.citricWeightGrams, closeTo(51.63, 0.001));
      expect(product.finalProductWeightGrams, closeTo(206.51, 0.001));
      expect(product.kilogramsForAmount(50), closeTo(10.3255, 0.001));
      expect(product.hasWeightFormula, true);
      expect(product.customWeightRangeMinGrams, isNull);
      expect(product.customWeightRangeMaxGrams, isNull);
    });

    test('keeps custom weight range grams', () {
      final product = ProductInfo(
        productName: 'Minion',
        target: 100,
        imageName: 'minion',
        product: const [Pressing('Yellow', 71.88, 23.96)],
        customWeightRangeMinGrams: 120,
        customWeightRangeMaxGrams: 130,
      );

      expect(product.customWeightRangeMinGrams, 120);
      expect(product.customWeightRangeMaxGrams, 130);
      final updated = product.copyWith(
        customWeightRangeMinGrams: 140,
        customWeightRangeMaxGrams: 150,
      );
      expect(updated.customWeightRangeMinGrams, 140);
      expect(updated.customWeightRangeMaxGrams, 150);
    });

    test('reports missing formula when no pressings are available', () {
      final product = ProductInfo.empty();

      expect(product.finalProductWeightGrams, 0);
      expect(product.kilogramsForAmount(50), 0);
      expect(product.hasWeightFormula, false);
    });

    test('reports missing formula when pressing weights are empty', () {
      final product = ProductInfo(
        productName: 'Minion',
        target: 100,
        imageName: 'minion',
        product: const [Pressing('', 0, 0)],
      );

      expect(product.finalProductWeightGrams, 0);
      expect(product.hasWeightFormula, false);
    });
  });

  group('ProductWeightSummary', () {
    testWidgets('uses default 5 percent range and rounds up', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductWeightSummary(weightGrams: 206.51, hasFormula: true),
          ),
        ),
      );

      expect(find.text('197-217 g'), findsOneWidget);
    });

    testWidgets('uses custom gram range', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductWeightSummary(
              weightGrams: 206.51,
              hasFormula: true,
              customMinGrams: 120,
              customMaxGrams: 130,
            ),
          ),
        ),
      );

      expect(find.text('120-130 g'), findsOneWidget);
    });

    testWidgets('uses custom gram range without split formula', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductWeightSummary(
              weightGrams: 0,
              hasFormula: false,
              customMinGrams: 120,
              customMaxGrams: 130,
            ),
          ),
        ),
      );

      expect(find.text('120-130 g'), findsOneWidget);
    });
  });
}
