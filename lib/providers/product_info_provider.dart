import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductInfoNotifier extends StateNotifier<List<ProductInfo>> {
  ProductInfoNotifier(this._repository) : super([]) {
    _loadProductInfoOnInit();
  }
  final ProductInfoRepository _repository;

  void _loadProductInfoOnInit() {
    // Immediately executed async function to load product info on init
    scheduleMicrotask(loadProductInfo);
  }

  Future<void> loadProductInfo() async {
    state = await _repository.fetchProductInfo();
  }

  Future<void> addProductInfo(
    String productName,
    int target,
    List<Pressing> pressings, {
    double? customWeightRangeMinGrams,
    double? customWeightRangeMaxGrams,
  }) async {
    await _repository.addProduct(
      productName,
      target,
      pressings,
      customWeightRangeMinGrams: customWeightRangeMinGrams,
      customWeightRangeMaxGrams: customWeightRangeMaxGrams,
    );
    // Reload the product info to update the state
    await loadProductInfo();
  }

  Future<bool> editProductInfo(ProductInfo product) async {
    final success = await _repository.editProductInfo(product);
    if (success) {
      await loadProductInfo();
      return true;
    } else {
      return false;
    }
  }

  Future<void> deleteProduct(String productName) async {
    await _repository.deleteProduct(productName);
    // Reload the product info to update the state
    await loadProductInfo();
  }
}

final productInfoProvider =
    StateNotifierProvider<ProductInfoNotifier, List<ProductInfo>>((ref) {
      final repository = ref.read(productInfoRepo);
      return ProductInfoNotifier(repository);
    });

final productInfoRepo = Provider<ProductInfoRepository>(
  (ref) => ProductInfoRepository(),
);

final focusedProductProvider = StateProvider<ProductInfo>(
  (ref) => ProductInfo(
    productName: '',
    product: [const Pressing('', 0, 0)],
    imageName: 'question',
    target: 0,
  ),
);

final bonusTableSelectorProvider = StateProvider<bool>((ref) => false);
