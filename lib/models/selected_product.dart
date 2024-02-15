


import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'selected_product.g.dart';

@HiveType(typeId: 6) // Specify a unique typeId for ProductInfo
class SelectedProduct extends HiveObject {
  // Ensure Product model is a Hive object

  SelectedProduct({
    required this.date,
    required this.productInfo,
  });
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final ProductInfo productInfo;
}
