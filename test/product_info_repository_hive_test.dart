import 'dart:io';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository_hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late ProductInfoRepositoryHive repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ProductInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PressingAdapter());
    }
    repo = ProductInfoRepositoryHive();
    await Hive.openBox<ProductInfo>('productInfo');
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteBoxFromDisk('productInfo');
    await tempDir.delete(recursive: true);
  });

  test('addProduct stores product and fetchProductInfo retrieves it', () async {
    const pressing = Pressing('Red', 1, 2);
    final product = ProductInfo(
      productName: 'Widget',
      target: 100,
      imageName: 'Widget',
      product: [pressing],
    );

    await repo.addProduct(product);
    final products = await repo.fetchProductInfo();
    expect(products.length, 1);
    expect(products.first.productName, 'Widget');
  });

  test('editProductInfo updates an existing product', () async {
    const pressing = Pressing('Blue', 2, 3);
    final product = ProductInfo(
      productName: 'Gadget',
      target: 50,
      imageName: 'Gadget',
      product: [pressing],
    );

    await repo.addProduct(product);
    final updated = product.copyWith(target: 75);
    final result = await repo.editProductInfo(updated);
    expect(result, true);

    final products = await repo.fetchProductInfo();
    expect(products.first.target, 75);
  });

  test('deleteProduct removes product from box', () async {
    const pressing = Pressing('Green', 3, 4);
    final product = ProductInfo(
      productName: 'Thing',
      target: 20,
      imageName: 'Thing',
      product: [pressing],
    );

    await repo.addProduct(product);
    await repo.deleteProduct('Thing');
    final products = await repo.fetchProductInfo();
    expect(products, isEmpty);
  });
}
