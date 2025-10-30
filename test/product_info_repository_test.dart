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
    await repo.addProduct('Widget', 100, [pressing]);

    final products = await repo.fetchProductInfo();
    expect(products.length, 1);
    expect(products.first.productName, 'Widget');
  });

  test('editProductInfo updates product in Firestore', () async {
    const pressing = Pressing('Blue', 2, 3);
    await repo.addProduct('Gadget', 50, [pressing]);

    final updated = ProductInfo(
      productName: 'Gadget',
      target: 75,
      imageName: 'Gadget',
      product: [pressing],
    );
    final result = await repo.editProductInfo(updated);
    expect(result, true);

    final products = await repo.fetchProductInfo();
    expect(products.first.target, 75);
  });

  test('deleteProduct removes product from Firestore', () async {
    const pressing = Pressing('Green', 3, 4);
    await repo.addProduct('Thing', 20, [pressing]);

    await repo.deleteProduct('Thing');
    final products = await repo.fetchProductInfo();
    expect(products, isEmpty);
  });
}
