import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductInfoRepository {
  ProductInfoRepository(this._productInfoBox);
  final Box<ProductInfo> _productInfoBox;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<ProductInfo>> fetchProductInfo() async {
    return _productInfoBox.values.toList();
  }

  Future<void> addProduct(String productName, int target, List<Pressing> pressings) async {
    // Convert the product name to title case
    final formattedProductName = toTitleCase(productName);

    // Open the Hive box for ProductInfo objects
    final box = Hive.box<ProductInfo>('ProductInfo');

    // Check if a product with the same name already exists
    if (box.values.any((product) => product.productName == formattedProductName)) {
      // If the product already exists, throw an error or return
      throw Exception('A product with the same name already exists');
    } else {
      final newProduct = ProductInfo(
        productName: formattedProductName,
        imageName: formattedProductName,
        target: target,
        product: pressings,
      );
      // Add the new product to the Hive box
      await box.add(newProduct); // Use add to generate a unique key automatically
    }
    await updateRemotePressingTargets();
  }

  Future<void> updateRemotePressingTargets() async {
    final box = Hive.box<ProductInfo>('ProductInfo');
    final dataToUpdate = <String, dynamic>{};

    // Prepare the data to update
    for (final product in box.values) {
      dataToUpdate[product.productName] = {
        'target': product.target,
        'pressings': product.product.map((pressing) => {
          'color': pressing.productColor,
          'systemG': pressing.systemG,
          'systemCitric': pressing.systemCitric,
        },).toList(),
      };
    }

    // Assuming db is a Firestore instance, update the Firestore document
    await db.collection('targets').doc('pressing').set(dataToUpdate);
  }

  Future<void> deleteProduct(String productName) async {
    // Convert the product name to title case
    final formattedProductName = toTitleCase(productName);

    // Open the Hive box
    final box = Hive.box<ProductInfo>('ProductInfo');

    // Check if a product with the given name exists
    if (box.containsKey(formattedProductName)) {
      // If the product exists, delete it from the Hive box
      await box.delete(formattedProductName);
    } else {
      // If the product does not exist, throw an error or return
      throw Exception('No product found with the given name');
    }

    // Update remote pressing targets after deletion
    await updateRemotePressingTargets();
  }
}
