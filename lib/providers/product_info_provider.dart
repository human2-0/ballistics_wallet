import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';


class ProductInfoNotifier extends StateNotifier<List<ProductInfo>> {
  ProductInfoNotifier(this._repository) : super([]) {
    _loadProductInfoOnInit();
  }
  final ProductInfoRepository _repository;

  void _loadProductInfoOnInit() {
    // Immediately executed async function to load product info on init
    Future(() async {
      await loadProductInfo();
    });
  }

  Future<void> loadProductInfo() async {
    state = await _repository.fetchProductInfo();
  }

  Future<void> addProductInfo(String productName, int target, List<Pressing> pressings) async {
    await _repository.addProduct(productName,target,pressings);
    // Reload the product info to update the state
    await loadProductInfo();
  }

  Future<void> deleteProduct(String productName) async {
    await _repository.deleteProduct(productName);
    // Reload the product info to update the state
    await loadProductInfo();
  }


}

final productInfoProvider =
    StateNotifierProvider<ProductInfoNotifier, List<ProductInfo>>((ref) {
  // You need to open your Hive box and pass it to the repository
  // Assuming you have a method to get your Hive box, e.g., Hive.box<ProductInfo>('product_info')
  final productInfoBox = Hive.box<ProductInfo>('ProductInfo');
  final repository = ProductInfoRepository(productInfoBox);
  return ProductInfoNotifier(repository);
});

final focusedProductProvider = StateProvider<ProductInfo>((ref) => ProductInfo(
    productName: '',
    product: [const Pressing('', 0, 0)],
    imageName: '',
    target: 0,),);
