import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class FocusNotifier extends StateNotifier<bool> {
  FocusNotifier() : super(false);

  Future<void> setFocus(bool focus) async {
    state = focus;
  }
}

class LastSelectedProductNotifier extends StateNotifier<List<SelectedProduct>> {
  LastSelectedProductNotifier() : super([]) {
    scheduleMicrotask(_initBox);
  }

  Future<void> _initBox() async {
    // Assuming Hive is initialized and SelectedProduct adapter is registered elsewhere
    await Hive.openBox<SelectedProduct>('selected_products');
    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final box = Hive.box<SelectedProduct>('selected_products');
    // Products are already sorted by date due to the box's structure
    final products =
        box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    state = products;
  }

  Future<void> saveSelectedProduct(ProductInfo productInfo) async {
    if (!Hive.isBoxOpen('selected_products')) {
      await Hive.openBox<SelectedProduct>('selected_products');
    }
    final box = Hive.box<SelectedProduct>('selected_products');
    final productKey =
        box.values
            .firstWhere(
              (item) => item.productInfo.productName == productInfo.productName,
              orElse:
                  () => SelectedProduct(
                    date: DateTime.now(),
                    productInfo: productInfo,
                  ),
            )
            .key;
    if (productKey != null) {
      await box.delete(productKey);
    }
    final selectedProduct = SelectedProduct(
      date: DateTime.now(),
      productInfo: productInfo,
    );
    // Since DateTime.now() is used as a key, ensure uniqueness or handle potential collisions
    await box.add(
      selectedProduct,
    ); // Using add as we don't need to specify a key

    await _fetchInitialData();
  }

  Future<void> deleteSelectedProductByName(String productName) async {
    final box = await Hive.openBox<SelectedProduct>('selected_products');
    // Find and delete the product by name
    final productKey =
        box.values
            .firstWhere(
              (item) => item.productInfo.productName == productName,
              orElse:
                  () => SelectedProduct(
                    date: DateTime.now(),
                    productInfo: ProductInfo(
                      productName: '',
                      imageName: '',
                      target: 0,
                      product: [],
                    ),
                  ),
            )
            .key;

    if (productKey != null) {
      await box.delete(productKey);
      await _fetchInitialData();
    }
  }
}
