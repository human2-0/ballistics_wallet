import 'package:hive/hive.dart';

part 'product_name.g.dart';  // Hive's TypeAdapter generator

@HiveType(typeId: 0) // Use a unique typeId for each HiveObject type
class ProductName {
  ProductName({required this.name, required this.target, this.imageName});

  // Factory constructor to create a ProductName from a Map entry
  factory ProductName.fromMapEntry(MapEntry<String, dynamic> entry) {
    int target;
    if (entry.value == null) {
      throw ArgumentError('Target value cannot be null.');
    } else if (entry.value is int) {
      target = entry.value as int;
    } else {
      final error = entry.value as int;
      throw FormatException('Expected an integer for target but found: ${error.runtimeType}');
    }

    return ProductName(
      name: entry.key,
      target: target,
    );
  }

  @HiveField(0)
  final String name;

  @HiveField(1)
  final int target;

  @HiveField(2)
  final String? imageName;
}
