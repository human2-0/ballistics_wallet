import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository_hive.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductInfoNotifierHive extends StateNotifier<List<ProductInfo>> {
  ProductInfoNotifierHive(this._repository) : super([]) {
    scheduleMicrotask(loadProductInfo);
  }

  final ProductInfoRepositoryHive _repository;

  Future<void> loadProductInfo() async {
    state = await _repository.fetchProductInfo();
  }

  Future<void> addProductInfo(ProductInfo product) async {
    await _repository.addProduct(product);
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
    await loadProductInfo();
  }
}

final productInfoProviderHive =
    StateNotifierProvider<ProductInfoNotifierHive, List<ProductInfo>>((ref) {
      final repository = ProductInfoRepositoryHive();
      return ProductInfoNotifierHive(repository);
    });
