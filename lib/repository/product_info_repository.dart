import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductInfoRepository {
  ProductInfoRepository();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<ProductInfo>> fetchProductInfo() async {
    // Fetch data directly from Firestore
    final querySnapshot = await db.collection('targets').doc('pressing').get();

    final products = <ProductInfo>[];
    if (querySnapshot.exists) {
     querySnapshot.data()!.forEach((productName, productData) {
        products.add(_fromMapToProductInfo(
          productName, productData as Map<String, dynamic>,
        ),);
      });
    }
    return products;
  }


  // Helper method to convert Firestore data to ProductInfo objects
  ProductInfo _fromMapToProductInfo(
      String productName, Map<String, dynamic> data,) {
    return ProductInfo(
      productName: productName,
      target: data['target'] as int,
      imageName: productName, // Assuming the imageName follows the productName
      // Correctly cast and map pressings to Pressing objects
      product: (data['pressings'] as List)
          .map((pressing) => Pressing.fromMap(pressing as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> addProduct(String productName, int target, List<Pressing> pressings) async {
    final formattedProductName = toTitleCase(productName);

    final productData = {
      'target': target,
      'imageName': formattedProductName, // Assuming imageName follows productName
      'pressings': pressings.map((pressing) => pressing.toMap()).toList(),
    };

    // Check if product already exists (optional based on your Firestore structure)
    // Then add/update product in Firestore
    await db.collection('targets').doc('pressing').set({
      formattedProductName: productData,
    }, SetOptions(merge: true),); // Merge true to avoid overwriting entire document
  }

  Future<bool> editProductInfo(ProductInfo updatedProduct) async {
    try {
      final updatedProductData = {
        'target': updatedProduct.target,
        'imageName': updatedProduct.imageName,
        'pressings': updatedProduct.product.map((pressing) => pressing.toMap()).toList(),
      };

      await db.collection('targets').doc('pressing').set({
        updatedProduct.productName: updatedProductData,
      }, SetOptions(merge: true),);

      return true; // Update was successful
    } on FormatException catch (e) {
      return false; // Update failed
    }
  }



  Future<void> deleteProduct(String productName) async {
    // Remove the product entry from the Firestore document
    await db.collection('targets').doc('pressing').update({
      productName: FieldValue.delete(),
    });
  }
}
