import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductInfoRepository {
  ProductInfoRepository({FirebaseFirestore? firestore})
      : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;

  Future<List<ProductInfo>> fetchProductInfo() async {
    // Fetch data directly from Firestore
    final querySnapshot = await db.collection('targets').doc('pressing').get();

    final products = <ProductInfo>[];
    if (querySnapshot.exists) {
      querySnapshot.data()!.forEach((productName, productData) {
        products.add(
          _fromMapToProductInfo(
            productName,
            productData as Map<String, dynamic>,
          ),
        );
      });
    }
    return products;
  }

  // Helper method to convert Firestore data to ProductInfo objects
  ProductInfo _fromMapToProductInfo(
    String productName,
    Map<String, dynamic> data,
  ) =>
      ProductInfo(
        productName: productName,
        target: data['target'] as int,
        imageName: toTitleCase(
          productName,
        ), // Assuming the imageName follows the productName
        // Correctly cast and map pressings to Pressing objects
        product: (data['pressings'] as List)
            .map(
              (pressing) => Pressing.fromMap(pressing as Map<String, dynamic>),
            )
            .toList(),
        ayr: data['ayr'] as bool?,
        description: data['description'] as String?,
      );

  Future<void> addProduct(
    String productName,
    int target,
    List<Pressing> pressings,
  {bool ayr = true,String? description,}
  ) async {
    final formattedProductName = toTitleCase(productName);

    final productData = {
      'target': target,
      'imageName':
          formattedProductName, // Assuming imageName follows productName
      'pressings': pressings.map((pressing) => pressing.toMap()).toList(),
      'ayr': ayr,
      'description': description,
    };

    // Check if product already exists (optional based on your Firestore structure)
    // Then add/update product in Firestore
    await db.collection('targets').doc('pressing').set(
      {
        productName: productData,
      },
      SetOptions(merge: true),
    ); // Merge true to avoid overwriting entire document
  }

  Future<bool> editProductInfo(ProductInfo updatedProduct) async {
    try {
      final updatedProductData = {
        'target': updatedProduct.target,
        'imageName': updatedProduct.imageName,
        'ayr': updatedProduct.ayr,
        'pressings':
            updatedProduct.product.map((pressing) => pressing.toMap()).toList(),
        'description': updatedProduct.description,
      };

      await db.collection('targets').doc('pressing').set(
        {
          updatedProduct.productName: updatedProductData,
        },
        SetOptions(merge: true),
      );

      // await fetchProductInfo();

      return true; // Update was successful
    } on FormatException {
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
