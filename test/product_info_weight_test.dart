import 'package:ballistics_wallet_flutter/models/product_info.dart';
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
      expect(product.hasWeightFormula, true);
    });

    test('reports missing formula when no pressings are available', () {
      final product = ProductInfo.empty();

      expect(product.finalProductWeightGrams, 0);
      expect(product.hasWeightFormula, false);
    });
  });
}
