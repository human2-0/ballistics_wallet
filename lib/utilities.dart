import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/adapters.dart';

import 'models/product_name.dart';
import 'models/product_split.dart';
import 'models/selected_product_history.dart';

String formatDouble(double value) {
  return value == value.floor() ? value.floor().toString() : value.toStringAsFixed(2);
}

String formatProductNameToFileName(String productName) {
  String fileName = productName.toLowerCase();

  // Remove any special characters or numbers
  fileName = fileName.replaceAll(RegExp(r'[^a-z ]'), '');

  // Replace spaces with underscores
  fileName = fileName.replaceAll(' ', '_');

  // Remove any trailing underscores
  fileName = fileName.replaceAll(RegExp(r'_+$'), '');

  return fileName;
}

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  return text.toLowerCase().split(' ').map((word) {
    final String leftText = word.length > 1 ? word.substring(1) : '';
    return word[0].toUpperCase() + leftText;
  }).join(' ');
}

DateTime nextMonday() {
  DateTime now = DateTime.now();
  int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
  return now.add(Duration(days: daysUntilMonday));
}

Future<void> loadDataFromCSV() async {
  final rawData = await rootBundle.loadString('new_targets.csv');
  final rows = csvToList(rawData);

  var boxNames = await Hive.openBox<ProductName>('Products');

  for (var row in rows) {
    if (row.length < 2) continue;

    var productName = row[0]?.toString().trim();
    var targetString = row[1]?.toString().replaceAll(RegExp(r'[,"]'), '').trim();
    var cleanedTargetString = targetString?.replaceAll(RegExp(r'[^0-9]'), '');
    var target = int.tryParse(cleanedTargetString!);
    String? imageName = row.length >= 3 ? row[2]?.toString().trim() : null;

    if (productName != null && productName.isNotEmpty && target != null && target != 0) {
      var product = ProductName(name: productName, target: target, imageName: imageName);
      await boxNames.put(productName, product);
    }
  }
}

List<List<dynamic>> csvToList(String data) {
  String eol = data.contains('\r\n') ? '\r\n' : '\n';
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
      boxSplit.add(product);
    }
  }
}

Future<void> initHive() async {
  await Hive.initFlutter();


  Hive.registerAdapter(ProductNameAdapter());
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(SelectedProductAdapter());

  var boxNames = await Hive.openBox<ProductName>('Products');
  var boxSplit = await Hive.openBox<Product>('products_split');


  boxNames.clear();
  boxSplit.clear();

  await addDataToHiveBoxProductSplit(boxSplit);
}
