import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProductInfoRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ProductInfoRepository(firestore: firestore);
  });

  test('addProduct and fetchProductInfo work with Firestore', () async {
    const pressing = Pressing('Red', 1, 2);
    await repo.addProduct(
      'Widget',
      100,
      [pressing],
      customWeightRangeMinGrams: 120,
      customWeightRangeMaxGrams: 130,
    );

    final products = await repo.fetchProductInfo();
    expect(products.length, 1);
    expect(products.first.productName, 'Widget');
    expect(products.first.customWeightRangeMinGrams, 120);
    expect(products.first.customWeightRangeMaxGrams, 130);
  });

  test('editProductInfo updates product in Firestore', () async {
    const pressing = Pressing('Blue', 2, 3);
    await repo.addProduct('Gadget', 50, [pressing]);

    final updated = ProductInfo(
      productName: 'Gadget',
      target: 75,
      imageName: 'Gadget',
      product: [pressing],
      customWeightRangeMinGrams: 210,
      customWeightRangeMaxGrams: 225,
    );
    final result = await repo.editProductInfo(updated);
    expect(result, true);

    final products = await repo.fetchProductInfo();
    expect(products.first.target, 75);
    expect(products.first.imageName, 'Gadget');
    expect(products.first.customWeightRangeMinGrams, 210);
    expect(products.first.customWeightRangeMaxGrams, 225);
  });

  test('fetchProductInfo falls back to product-name image slug', () async {
    await firestore.collection('targets').doc('pressing').set({
      'Sticky Dates Bath Bomb': {
        'target': 100,
        'pressings': [const Pressing('Brown', 1, 2).toMap()],
      },
    });

    final products = await repo.fetchProductInfo();
    expect(products.single.imageName, 'sticky_dates_bath_bomb');
    expect(products.single.customWeightRangeMinGrams, isNull);
    expect(products.single.customWeightRangeMaxGrams, isNull);
  });

  test('deleteProduct removes product from Firestore', () async {
    const pressing = Pressing('Green', 3, 4);
    await repo.addProduct('Thing', 20, [pressing]);

    await repo.deleteProduct('Thing');
    final products = await repo.fetchProductInfo();
    expect(products, isEmpty);
  });
}
