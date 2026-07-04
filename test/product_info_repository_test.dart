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
    expect(products.first.imageScale, 1);
    expect(products.first.imageOffsetX, 0);
    expect(products.first.imageOffsetY, 0);
  });

  test(
    'addProduct uses a colour placeholder without split pressings',
    () async {
      await repo.addProduct(
        'Widget',
        100,
        const [],
        customWeightRangeMinGrams: 120,
        customWeightRangeMaxGrams: 130,
      );

      final products = await repo.fetchProductInfo();
      expect(products.length, 1);
      expect(products.first.productName, 'Widget');
      expect(products.first.product, const [Pressing.placeholder]);
      expect(products.first.hasWeightFormula, isFalse);
      expect(products.first.customWeightRangeMinGrams, 120);
      expect(products.first.customWeightRangeMaxGrams, 130);
    },
  );

  test('editProductInfo accepts the quick-create colour placeholder', () async {
    await repo.addProduct('Widget', 100, const []);

    final product = (await repo.fetchProductInfo()).single;
    final result = await repo.editProductInfo(product.copyWith(target: 125));

    expect(result, isTrue);
    final updated = (await repo.fetchProductInfo()).single;
    expect(updated.target, 125);
    expect(updated.product, const [Pressing.placeholder]);
  });

  test(
    'real split data replaces the quick-create colour placeholder',
    () async {
      await repo.addProduct('Widget', 100, const []);
      final product = (await repo.fetchProductInfo()).single;

      final result = await repo.editProductInfo(
        product.copyWith(
          product: [...product.product, const Pressing('Blue', 2, 1)],
        ),
      );

      expect(result, isTrue);
      final updated = (await repo.fetchProductInfo()).single;
      expect(updated.product, const [Pressing('Blue', 2, 1)]);
    },
  );

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
      imageScale: 1.8,
      imageOffsetX: -0.2,
      imageOffsetY: 0.15,
    );
    final result = await repo.editProductInfo(updated);
    expect(result, true);

    final products = await repo.fetchProductInfo();
    expect(products.first.target, 75);
    expect(products.first.imageName, 'Gadget');
    expect(products.first.customWeightRangeMinGrams, 210);
    expect(products.first.customWeightRangeMaxGrams, 225);
    expect(products.first.imageScale, 1.8);
    expect(products.first.imageOffsetX, -0.2);
    expect(products.first.imageOffsetY, 0.15);
  });

  test(
    'editProductInfo can store weight range without split pressings',
    () async {
      const pressing = Pressing('Blue', 2, 3);
      await repo.addProduct('Gadget', 50, [pressing]);

      final updated = ProductInfo(
        productName: 'Gadget',
        target: 75,
        imageName: 'Gadget',
        product: const [],
        customWeightRangeMinGrams: 210,
        customWeightRangeMaxGrams: 225,
      );
      final result = await repo.editProductInfo(updated);
      expect(result, true);

      final products = await repo.fetchProductInfo();
      expect(products.first.product, isEmpty);
      expect(products.first.customWeightRangeMinGrams, 210);
      expect(products.first.customWeightRangeMaxGrams, 225);
    },
  );

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
    expect(products.single.imageScale, 1);
    expect(products.single.imageOffsetX, 0);
    expect(products.single.imageOffsetY, 0);
  });

  test('deleteProduct removes product from Firestore', () async {
    const pressing = Pressing('Green', 3, 4);
    await repo.addProduct('Thing', 20, [pressing]);

    await repo.deleteProduct('Thing');
    final products = await repo.fetchProductInfo();
    expect(products, isEmpty);
  });
}
