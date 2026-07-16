import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/services/product_search_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProductInfo product(String name) => ProductInfo(
    productName: name,
    target: 1,
    imageName: 'question',
    product: const [Pressing('', 0, 0)],
  );

  final products = [
    product('Big Blue'),
    product('Butterball'),
    product('Butterbear'),
    product("Dragon's Egg '21 - New Flat Base"),
    product('Intergalactic'),
    product('Snow Fairy'),
  ];

  test('finds a product when one character is missing', () {
    final results = searchProducts(products, 'intergalatic');

    expect(results.first.productName, 'Intergalactic');
  });

  test('handles transposed letters in multiple words', () {
    final results = searchProducts(products, 'snwo fariy');

    expect(results.first.productName, 'Snow Fairy');
  });

  test('normalizes punctuation and ranks literal matches first', () {
    final results = searchProducts(products, 'dragons egg');

    expect(results.first.productName, "Dragon's Egg '21 - New Flat Base");
  });

  test('ranks an exact spelling ahead of a fuzzy alternative', () {
    final candidates = [product('Butterball'), product('Buterball Special')];

    final results = searchProducts(candidates, 'buterball');

    expect(results.map((candidate) => candidate.productName), [
      'Buterball Special',
      'Butterball',
    ]);
  });

  test('does not make noisy fuzzy matches for very short queries', () {
    final results = searchProducts(products, 'bt');

    expect(results, isEmpty);
  });

  test('returns no suggestion when the query is too different', () {
    final results = searchProducts(products, 'zzzzzz');

    expect(results, isEmpty);
  });
}
