import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'product_info.g.dart'; // Hive generates this part file

@HiveType(typeId: 3) // Specify a unique typeId for ProductInfo
class ProductInfo extends HiveObject {
  // Constructor for ProductInfo
  ProductInfo({
    required this.productName,
    required this.target,
    required this.imageName,
    required this.product,
    this.ayr,
    this.description,
    this.customWeightRangeMinGrams,
    this.customWeightRangeMaxGrams,
    this.imageScale = 1,
    this.imageOffsetX = 0,
    this.imageOffsetY = 0,
  });

  // Empty constructor for creating an instance with default values
  factory ProductInfo.empty() => ProductInfo(
    productName: '',
    target: 0,
    imageName: '',
    product: const [],
    description: '',
  );

  static const double defaultWeightRangePercent = 5;

  @HiveField(0)
  final String productName;

  @HiveField(1)
  final int target;

  @HiveField(2)
  final String imageName;

  @HiveField(3)
  final List<Pressing> product;

  @HiveField(4)
  final bool? ayr;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final double? customWeightRangeMinGrams;

  @HiveField(7)
  final double? customWeightRangeMaxGrams;

  /// Zoom applied to the product image in the target checker.
  @HiveField(8, defaultValue: 1.0)
  final double imageScale;

  /// Horizontal image framing as a fraction of the image viewport width.
  @HiveField(9, defaultValue: 0.0)
  final double imageOffsetX;

  /// Vertical image framing as a fraction of the image viewport height.
  @HiveField(10, defaultValue: 0.0)
  final double imageOffsetY;

  /// Total powder weight needed for one finished product.
  double get powderWeightGrams =>
      product.fold<double>(0, (total, pressing) => total + pressing.systemG);

  /// Total citric weight needed for one finished product.
  double get citricWeightGrams => product.fold<double>(
    0,
    (total, pressing) => total + pressing.systemCitric,
  );

  /// Expected finished weight for one product, calculated from split data.
  double get finalProductWeightGrams => powderWeightGrams + citricWeightGrams;

  /// Total powder and citric weight for a produced amount, in kilograms.
  double kilogramsForAmount(int amount) {
    if (amount <= 0 || !hasWeightFormula) return 0;
    return amount * finalProductWeightGrams / 1000;
  }

  /// Whether this product has enough split data to calculate finished weight.
  bool get hasWeightFormula => product.any(
    (pressing) => pressing.systemG > 0 || pressing.systemCitric > 0,
  );

  bool get hasCustomWeightRange =>
      customWeightRangeMinGrams != null && customWeightRangeMaxGrams != null;

  // Method to create a copy of ProductInfo with different fields
  ProductInfo copyWith({
    String? productName,
    int? target,
    String? imageName,
    List<Pressing>? product,
    bool? ayr,
    String? description,
    double? customWeightRangeMinGrams,
    double? customWeightRangeMaxGrams,
    double? imageScale,
    double? imageOffsetX,
    double? imageOffsetY,
  }) => ProductInfo(
    productName: productName ?? this.productName,
    target: target ?? this.target,
    imageName: imageName ?? this.imageName,
    product: product ?? this.product,
    ayr: ayr ?? this.ayr,
    description: description ?? this.description,
    customWeightRangeMinGrams:
        customWeightRangeMinGrams ?? this.customWeightRangeMinGrams,
    customWeightRangeMaxGrams:
        customWeightRangeMaxGrams ?? this.customWeightRangeMaxGrams,
    imageScale: imageScale ?? this.imageScale,
    imageOffsetX: imageOffsetX ?? this.imageOffsetX,
    imageOffsetY: imageOffsetY ?? this.imageOffsetY,
  );
}

@immutable
@HiveType(typeId: 4)
class Pressing {
  const Pressing(this.productColor, this.systemG, this.systemCitric);

  factory Pressing.fromMap(Map<String, dynamic> map) => Pressing(
    map['color'] as String,
    (map['systemG'] as num).toDouble(),
    (map['systemCitric'] as num).toDouble(),
  );

  /// Split used when a product is created before its colour recipe is known.
  static const placeholder = Pressing('Colour to be confirmed', 0, 0);

  @HiveField(1)
  final String productColor;

  @HiveField(2)
  final double systemG;

  @HiveField(3)
  final double systemCitric;

  bool get isPlaceholder => productColor.trim() == placeholder.productColor;

  Pressing copyWith({
    String? productColor,
    double? systemG,
    double? systemCitric,
  }) => Pressing(
    productColor ?? this.productColor,
    systemG ?? this.systemG,
    systemCitric ?? this.systemCitric,
  );

  Map<String, dynamic> toMap() => {
    'color': productColor,
    'systemG': systemG,
    'systemCitric': systemCitric,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pressing &&
        other.productColor == productColor &&
        other.systemG == systemG &&
        other.systemCitric == systemCitric;
  }

  @override
  int get hashCode =>
      productColor.hashCode ^ systemG.hashCode ^ systemCitric.hashCode;
}
