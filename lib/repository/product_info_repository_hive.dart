import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:hive/hive.dart';

class ProductInfoRepositoryHive {
  Box<ProductInfo> get _productBox => Hive.box<ProductInfo>('productInfo');

  Future<List<ProductInfo>> fetchProductInfo() async =>
      _productBox.values.toList();

  Future<void> addProduct(ProductInfo product) async {
    await _productBox.put(product.productName, product);
  }

  Future<bool> editProductInfo(ProductInfo updatedProduct) async {
    try {
      await _productBox.put(updatedProduct.productName, updatedProduct);
      return true;
    } on FormatException {
      return false;
    }
  }

  Future<void> deleteProduct(String productName) async {
    await _productBox.delete(productName);
  }
}
