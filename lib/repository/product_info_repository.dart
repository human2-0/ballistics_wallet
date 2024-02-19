import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProductInfoRepository {
  ProductInfoRepository();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<ProductInfo>> fetchProductInfo() async {
    // Fetch data from Firestore instead of the local Hive box
    final querySnapshot = await db.collection('targets').doc('pressing').get();

    if (querySnapshot.exists) {
      final data = querySnapshot.data()!;
      final products = <ProductInfo>[];
      data.forEach((productName, productData) {
        // Correctly cast productData to Map<String, dynamic>
        products.add(_fromMapToProductInfo(productName, productData as Map<String, dynamic>));
      });
      return products;
    } else {
      return [];
    }
  }

  // Helper method to convert Firestore data to ProductInfo objects
  ProductInfo _fromMapToProductInfo(String productName, Map<String, dynamic> data) {
    return ProductInfo(
      productName: productName,
      target: data['target'] as int,
      imageName: productName, // Assuming the imageName follows the productName
      // Correctly cast and map pressings to Pressing objects
      product: (data['pressings'] as List).map((pressing) => Pressing.fromMap(pressing as Map<String, dynamic>)).toList(),
    );
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
    // Assume productName is used exactly as it's received, without conversion
    final box = Hive.box<ProductInfo>('ProductInfo');

    ProductInfo? productToDelete;
    try {
      productToDelete = box.values.firstWhere((product) => product.productName == productName);
    } on FormatException {
      productToDelete = null;
    }

    if (productToDelete != null) {
      await productToDelete.delete(); // Delete from Hive
    } else {
      // Optionally, handle the non-existence case, e.g., UI feedback
    }

    await db.collection('targets').doc('pressing').update({
      productName: FieldValue.delete(), // Delete from Firestore
    });

    await updateRemotePressingTargets(); // Update Firestore after deletion
  }





}
