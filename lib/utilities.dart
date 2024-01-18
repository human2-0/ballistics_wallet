import 'package:ballistics_wallet_flutter/models/product_name.dart';
import 'package:ballistics_wallet_flutter/models/product_split.dart';
import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/adapters.dart';

String formatDouble(double value) => value == value.floor()
    ? value.floor().toString()
    : value.toStringAsFixed(2);

String formatProductNameToFileName(String productName) {
  var fileName = productName.toLowerCase();

  // Remove any special characters or numbers
  fileName = fileName.replaceAll(RegExp('[^a-z ]'), '');

  // Replace spaces with underscores
  fileName = fileName.replaceAll(' ', '_');

  // Remove any trailing underscores
  fileName = fileName.replaceAll(RegExp(r'_+$'), '');

  return fileName;
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  return text.toLowerCase().split(' ').map((word) {
    final leftText = word.length > 1 ? word.substring(1) : '';
    return word[0].toUpperCase() + leftText;
  }).join(' ');
}

DateTime nextMonday() {
  final now = DateTime.now();
  final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
  return now.add(Duration(days: daysUntilMonday));
}

// Future<void> loadDataFromCSV() async {
//   final rawData = await rootBundle.loadString('new_targets.csv');
//   final rows = csvToList(rawData);
//
//   final boxNames = await Hive.openBox<ProductName>('Products');
//
//   for (final row in rows) {
//     if (row.length < 2) continue;
//
//     final productName = row[0]?.toString().trim();
//     final targetString = row[1]?.toString().replaceAll(RegExp('[,"]'), '').trim();
//     final cleanedTargetString = targetString?.replaceAll(RegExp('[^0-9]'), '');
//     final target = int.tryParse(cleanedTargetString!);
//
//     // Add print statements to debug
//
//     final imageName = row.length >= 3 ? row[2]?.toString().trim() : null;
//
//     if (productName != null && productName.isNotEmpty && target != null && target != 0) {
//       final product = ProductName(name: productName, target: target, imageName: imageName);
//       await boxNames.put(productName, product);
//     } else {
//       // Print a message if product is skipped
//     }
//   }
// }

List<List<dynamic>> csvToList(String data) {
  final eol = data.contains('\r\n') ? '\r\n' : '\n';
  return CsvToListConverter(eol: eol).convert(data);
}

Future<void> addDataToHiveBoxProductSplit(Box<Product> boxSplit) async {
  final data = await rootBundle.loadString('split_data.csv');
  final rows = csvToList(data);

  for (final row in rows) {
    if (row.isEmpty ||
        row[0] == null ||
        row[1] == null ||
        row[2] == null ||
        row[3] == null) {
      continue;
    }

    final product = Product(
      row[0].toString(),
      row[1].toString(),
      double.tryParse(row[2].toString()) ?? 0.0,
      double.tryParse(row[3].toString()) ?? 0.0,
    );

    if (product.productName.isNotEmpty &&
        product.productColor.isNotEmpty &&
        product.systemG != 0.0 &&
        product.systemCitric != 0.0) {
      await boxSplit.add(product);
    }
  }
}

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive
    ..registerAdapter(ProductNameAdapter())
    ..registerAdapter(ProductAdapter())
    ..registerAdapter(SelectedProductAdapter());

  final boxNames = await Hive.openBox<ProductName>('Products');
  final boxSplit = await Hive.openBox<Product>('products_split');

  await boxNames.clear();
  await boxSplit.clear();

  await addDataToHiveBoxProductSplit(boxSplit);
}

extension MapExtensions on Map<String, dynamic> {
  double getDouble(String key, [double defaultValue = 0.0]) {
    final value = this[key];
    return value is double ? value : defaultValue;
  }

  List<T> getList<T>(String key) =>
      this[key] is List<T> ? this[key] as List<T> : [];

  T getValue<T>(String key, {T? defaultValue}) {
    final value = this[key];
    if (value is T) {
      return value;
    } else {
      return defaultValue as T;
    }
  }
}
