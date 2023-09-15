import 'package:hive/hive.dart';

part 'product_split.g.dart';

@HiveType(typeId: 1)
class Product {
  @HiveField(0)
  final String productName;

  @HiveField(1)
  final String productColor;

  @HiveField(2)
  final double systemG;

  @HiveField(3)
  final double systemCitric;

  Product(this.productName, this.productColor, this.systemG, this.systemCitric);

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
  int get hashCode {
    return productName.hashCode ^
    productColor.hashCode ^
    systemG.hashCode ^
    systemCitric.hashCode;
  }
}