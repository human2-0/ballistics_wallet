

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';


String formatDouble(double value) => value == value.floor()
    ? value.floor().toString()
    : value.toStringAsFixed(2);

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  // Convert the string to lower case and split it into words
  var words = text.toLowerCase().split(' ');

  // Convert each word to title case
  words = words.map((word) {
    if (word.isEmpty) return word; // Check if the word is empty to avoid errors
    final leftText = word.length > 1 ? word.substring(1) : '';
    return word[0] + leftText;
  }).toList();

  // Join words with an underscore if there are multiple words
  return words.join('_');
}

List<List<dynamic>> csvToList(String data) {
  final eol = data.contains('\r\n') ? '\r\n' : '\n';
  return CsvToListConverter(eol: eol).convert(data);
}

Future<void> addDataToProductInfoBox(Box<ProductInfo> boxProductInfo) async {
  final data = await rootBundle.loadString('merged_data_final.csv');
  final rows = csvToList(data);

  // Map to hold products grouped by productName
  final productsByProductName = <String, List<Pressing>>{};

  for (final row in rows) {
    // Ensure the row has at least 7 columns for merged data
    if (row.length < 7) continue;

    final productName = row[0]?.toString().trim();

    // Parsing Pressing fields from the merged CSV
    final product = Pressing(
      row[3].toString(),
      double.tryParse(row[4].toString()) ?? 0.0,
      double.tryParse(row[5].toString()) ?? 0.0,
    );

    // Group products by productName
    if (productName != null && productName.isNotEmpty) {
      productsByProductName.putIfAbsent(productName, () => []);
      productsByProductName[productName]!.add(product);
    }
  }

  // Create and store ProductInfo instances
  for (final entry in productsByProductName.entries) {
    final productName = entry.key;
    final products = entry.value;

    // Assuming the target and imageName are the same for all products of the same productName.
    // Adjust this logic if target and imageName vary per product within the same productName.
    final targetString = rows
        .firstWhere((row) => row[0]?.toString().trim() == productName)[1]
        ?.toString()
        .replaceAll(RegExp('[,"]'), '')
        .trim();
    final cleanedTargetString = targetString?.replaceAll(RegExp('[^0-9]'), '');
    final target = int.tryParse(cleanedTargetString!);
    final imageName = rows
        .firstWhere((row) => row[0]?.toString().trim() == productName)[2]
        ?.toString()
        .trim();

    if (target != null && target != 0) {
      final productInfo = ProductInfo(
        productName: productName,
        target: target,
        imageName: imageName ?? '',
        product: products,
      );
      await boxProductInfo.put(productName, productInfo);
    }
  }
}

Future<void> initHive() async {
  await Hive.initFlutter();

  final docDir = await getApplicationDocumentsDirectory();
  final path = '${docDir.path}/hive';  // Construct the path with '/hive' directory

  Hive..init(path)



    ..registerAdapter(SelectedProductAdapter())
    ..registerAdapter(ProductInfoAdapter())
    ..registerAdapter(PressingAdapter())
    ..registerAdapter(BonusInfoAdapter())
    ..registerAdapter(ProducedAdapter());

  final boxProductInfo = await Hive.openBox<ProductInfo>('ProductInfo');
  if (boxProductInfo.isEmpty) {
    await addDataToProductInfoBox(boxProductInfo);
  }
  await Hive.openBox<BonusInfo>('bonusInfoBox');
}

Future<void> preloadImages(BuildContext context) async {
  // Load and cache images early
  final images = [
    'assets/login_screen.webp',
    'assets/target_screen.webp',
    'assets/wallet_screen.webp',
    'assets/profile_screen.webp',
  ];

  for (final imagePath in images) {
    await precacheImage(AssetImage(imagePath), context);
  }
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

const Map<int, double> bonusPercentageMap = {
  1: 102.00,
  2: 104.10,
  3: 106.10,
  4: 108.20,
  5: 110.20,
  6: 112.20,
  7: 114.29,
  8: 118.37,
  9: 122.45,
  10: 126.53,
  11: 130.61,
  12: 134.69,
  13: 138.78,
  14: 142.86,
  15: 146.94,
  16: 151.02,
  17: 155.10,
  18: 159.18,
  19: 163.27,
  20: 167.35,
  21: 171.43, //Add more values as per your requirements
};
