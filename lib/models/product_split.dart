import 'package:flutter/foundation.dart'; // Needed for @immutable
import 'package:hive/hive.dart';

part 'product_split.g.dart';

@immutable
@HiveType(typeId: 1)
class Product {

  const Product(this.productName, this.productColor, this.systemG, this.systemCitric);
  @HiveField(0)
  final String productName;

  @HiveField(1)
  final String productColor;

  @HiveField(2)
  final double systemG;

  @HiveField(3)
  final double systemCitric;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.productName == productName &&
        other.productColor == productColor &&
        other.systemG == systemG &&
        other.systemCitric == systemCitric;
  }

  @override
  int get hashCode => productName.hashCode ^
  productColor.hashCode ^
  systemG.hashCode ^
  systemCitric.hashCode;
}
