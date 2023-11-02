import 'package:hive/hive.dart';

part 'product_name.g.dart';  // Hive's TypeAdapter generator

@HiveType(typeId: 0)  // Use a unique typeId for each HiveObject type
class ProductName {  // Optional

  ProductName({required this.name, required this.target, this.imageName});
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int target;

  @HiveField(2)
  final String? imageName;
}
