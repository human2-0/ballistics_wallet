import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'product_info.g.dart'; // Hive generates this part file

@HiveType(typeId: 3) // Specify a unique typeId for ProductInfo
class ProductInfo extends HiveObject {
  // Ensure Product model is a Hive object

  ProductInfo({
    required this.productName,
    required this.target,
    required this.imageName,
    required this.product,
  });
  @HiveField(0)
  final String productName;

  @HiveField(1)
  final int target;

  @HiveField(2)
  final String imageName;

  @HiveField(3)
  final List<Pressing> product;

  ProductInfo copyWith({
    String? productName,
    int? target,
    String? imageName,
    List<Pressing>? product,
  }) => ProductInfo(
      productName: productName ?? this.productName,
      target: target ?? this.target,
      imageName: imageName ?? this.imageName,
      product: product ?? this.product,
    );
}

@immutable
@HiveType(typeId: 4)
class Pressing {
  const Pressing(this.productColor, this.systemG, this.systemCitric);

  // Factory constructor to create a Pressing instance from a map
  factory Pressing.fromMap(Map<String, dynamic> map) => Pressing(
      map['color'] as String,
      (map['systemG'] as num).toDouble(), // Ensuring type conversion to double
      (map['systemCitric'] as num)
          .toDouble(), // Ensuring type conversion to double
    );

  @HiveField(1)
  final String productColor;

  @HiveField(2)
  final double systemG;

  @HiveField(3)
  final double systemCitric;

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
