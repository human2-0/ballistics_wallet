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
  ) => ProductInfo(
    productName: productName,
    target: data['target'] as int,
    imageName: _imageNameFromData(productName, data),
    // Correctly cast and map pressings to Pressing objects
    product:
        (data['pressings'] as List)
            .map(
              (pressing) => Pressing.fromMap(pressing as Map<String, dynamic>),
            )
            .toList(),
    ayr: data['ayr'] as bool?,
    description: data['description'] as String?,
    customWeightRangeMinGrams: _customWeightRangeValueFromData(
      data,
      'customWeightRangeMinGrams',
    ),
    customWeightRangeMaxGrams: _customWeightRangeValueFromData(
      data,
      'customWeightRangeMaxGrams',
    ),
  );

  Future<void> addProduct(
    String productName,
    int target,
    List<Pressing> pressings, {
    bool ayr = true,
    String? description,
    double? customWeightRangeMinGrams,
    double? customWeightRangeMaxGrams,
  }) async {
    final cleanedProductName = productName.trim();
    final validPressings = _validatedPressings(pressings);
    if (cleanedProductName.isEmpty) {
      throw const FormatException('Product name is required.');
    }
    if (target <= 0) {
      throw const FormatException('Target must be greater than zero.');
    }

    final formattedProductName = productNameToImageName(cleanedProductName);

    final productData = {
      'target': target,
      'imageName': formattedProductName,
      'pressings': validPressings.map((pressing) => pressing.toMap()).toList(),
      'ayr': ayr,
      'description': description,
      'customWeightRangeMinGrams': customWeightRangeMinGrams,
      'customWeightRangeMaxGrams': customWeightRangeMaxGrams,
    };
    _validateCustomWeightRange(
      customWeightRangeMinGrams,
      customWeightRangeMaxGrams,
    );

    // Merge so one product edit does not overwrite the full pressing document.
    await db.collection('targets').doc('pressing').set(
      {cleanedProductName: productData},
      SetOptions(merge: true),
    ); // Merge true to avoid overwriting entire document
  }

  Future<bool> editProductInfo(ProductInfo updatedProduct) async {
    try {
      final validPressings = _validatedPressings(updatedProduct.product);
      if (updatedProduct.target <= 0) {
        throw const FormatException('Target must be greater than zero.');
      }

      final updatedProductData = {
        'target': updatedProduct.target,
        'imageName': updatedProduct.imageName,
        'ayr': updatedProduct.ayr,
        'pressings':
            validPressings.map((pressing) => pressing.toMap()).toList(),
        'description': updatedProduct.description,
        'customWeightRangeMinGrams': updatedProduct.customWeightRangeMinGrams,
        'customWeightRangeMaxGrams': updatedProduct.customWeightRangeMaxGrams,
      };
      _validateCustomWeightRange(
        updatedProduct.customWeightRangeMinGrams,
        updatedProduct.customWeightRangeMaxGrams,
      );

      await db.collection('targets').doc('pressing').set({
        updatedProduct.productName: updatedProductData,
      }, SetOptions(merge: true));

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

  String _imageNameFromData(String productName, Map<String, dynamic> data) {
    final imageName = data['imageName'];
    if (imageName is String && imageName.trim().isNotEmpty) {
      return imageName.trim();
    }
    return productNameToImageName(productName);
  }

  double? _customWeightRangeValueFromData(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];
    if (value is num && value > 0) {
      return value.toDouble();
    }
    return null;
  }

  void _validateCustomWeightRange(double? minGrams, double? maxGrams) {
    if (minGrams == null && maxGrams == null) return;
    if (minGrams == null || maxGrams == null) {
      throw const FormatException('Both weight range values are required.');
    }
    if (minGrams <= 0 || maxGrams <= 0 || minGrams > maxGrams) {
      throw const FormatException('Weight range must be valid grams.');
    }
  }

  List<Pressing> _validatedPressings(List<Pressing> pressings) {
    final validPressings =
        pressings
            .map(
              (pressing) =>
                  pressing.copyWith(productColor: pressing.productColor.trim()),
            )
            .where((pressing) => pressing.productColor.isNotEmpty)
            .toList();

    if (validPressings.isEmpty) {
      throw const FormatException('Add at least one colour and powder amount.');
    }

    for (final pressing in validPressings) {
      if (pressing.systemG <= 0 || pressing.systemCitric <= 0) {
        throw const FormatException(
          'Powder and citric amounts must be greater than 0.00.',
        );
      }
    }

    return validPressings;
  }
}
