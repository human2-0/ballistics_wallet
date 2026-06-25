import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/custom_date_range.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:ballistics_wallet_flutter/models/settings_version.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';

String formatDouble(double value, {int fractionDigits = 2}) =>
    value.toStringAsFixed(fractionDigits);

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  // Convert the string to lower case and split it into words
  var words = text.toLowerCase().split(' ');

  // Convert each word to title case
  words =
      words.map((word) {
        if (word.isEmpty) {
          return word; // Check if the word is empty to avoid errors
        }
        final leftText = word.length > 1 ? word.substring(1) : '';
        return word[0] + leftText;
      }).toList();

  // Join words with an underscore if there are multiple words
  return words.join('_');
}

String productNameToImageName(String productName) {
  final lower = productName.toLowerCase().trim();
  final withoutSlashes = lower.replaceAll(RegExp(r'[\\/]+'), ' ');
  final underscored = withoutSlashes.replaceAll(RegExp(r'\s+'), '_');
  final cleaned = underscored.replaceAll(RegExp("[^a-z0-9_'()-]+"), '_');
  return cleaned.replaceAll(RegExp('_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
}

List<List<dynamic>> csvToList(String data) => const CsvDecoder().convert(data);

Future<void> addDataToProductInfoBox(Box<ProductInfo> boxProductInfo) async {
  final data = await rootBundle.loadString('merged_data_final.csv');
  final rows = csvToList(data);
  final products = productInfoFromRows(rows);
  await boxProductInfo.putAll({
    for (final product in products) product.productName: product,
  });
}

/// Converts bundled product rows in one pass instead of repeatedly scanning
/// the complete CSV for each product.
List<ProductInfo> productInfoFromRows(List<List<dynamic>> rows) {
  final productsByName = <String, _ProductSeed>{};

  for (final row in rows) {
    if (row.length < 7) continue;

    final productName = row[0]?.toString().trim();
    if (productName == null || productName.isEmpty) continue;

    final seed = productsByName.putIfAbsent(
      productName,
      () => _ProductSeed(
        target: _parseProductTarget(row[1]),
        imageName: row[2]?.toString().trim() ?? '',
      ),
    );
    seed.pressings.add(
      Pressing(
        row[3].toString(),
        double.tryParse(row[4].toString()) ?? 0.0,
        double.tryParse(row[5].toString()) ?? 0.0,
      ),
    );
  }

  return [
    for (final entry in productsByName.entries)
      if (entry.value.target != null && entry.value.target != 0)
        ProductInfo(
          productName: entry.key,
          target: entry.value.target!,
          imageName: entry.value.imageName,
          product: entry.value.pressings,
        ),
  ];
}

int? _parseProductTarget(Object? value) {
  final cleaned = value?.toString().replaceAll(RegExp('[^0-9]'), '') ?? '';
  return int.tryParse(cleaned);
}

class _ProductSeed {
  _ProductSeed({required this.target, required this.imageName});

  final int? target;
  final String imageName;
  final List<Pressing> pressings = [];
}

Future<void> initHive() async {
  await Hive.initFlutter();

  final docDir = await getApplicationDocumentsDirectory();
  final path =
      '${docDir.path}/hive'; // Construct the path with '/hive' directory

  Hive
    ..init(path)
    ..registerAdapter(SelectedProductAdapter())
    ..registerAdapter(ProductInfoAdapter())
    ..registerAdapter(PressingAdapter())
    ..registerAdapter(BonusInfoAdapter())
    ..registerAdapter(ProducedAdapter())
    ..registerAdapter(UserSettingsAdapter())
    ..registerAdapter(CustomDateRangeAdapter())
    ..registerAdapter(SettingsVersionAdapter());

  final boxProductInfo = await Hive.openBox<ProductInfo>('ProductInfo');
  if (boxProductInfo.isEmpty) {
    await addDataToProductInfoBox(boxProductInfo);
  }
  await Hive.openBox<BonusInfo>('bonusInfoBox');
  await Hive.openBox<CustomDateRange>('customDateRangeBox');
  await openSettingsBox('settings');
}

Future<void> migrateSettingsBoxIfNeeded(String versionBoxName) async {
  final versionBox = await Hive.openBox<SettingsVersion>(versionBoxName);
  final storedVersion = versionBox.get(0);
  const currentSettingsVersion = 2;

  if (storedVersion == null || storedVersion.version < currentSettingsVersion) {
    // Delete the existing settings box due to version mismatch
    await Hive.deleteBoxFromDisk('settings');
    // Update the stored version
    await versionBox.put(0, SettingsVersion(version: currentSettingsVersion));
  }

  await versionBox.close(); // Close the version box after use
}

Future<Box<UserSettings>> openSettingsBox(String settingsBoxName) async {
  await migrateSettingsBoxIfNeeded('versionBox');

  Box<UserSettings> box;
  try {
    box = await Hive.openBox<UserSettings>(settingsBoxName);
  } on FormatException {
    // Fallback: Delete the box and create a new one
    await Hive.deleteBoxFromDisk(settingsBoxName);
    box = await Hive.openBox<UserSettings>(settingsBoxName);
  }

  return box;
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

String formatWorkingHours(double hours) {
  final wholeHours = hours.truncate(); // Get whole hours
  final minutes =
      ((hours - wholeHours) * 60).round(); // Convert decimal to minutes

  if (minutes == 0) {
    return '$wholeHours hours';
  } else {
    return '$wholeHours hours & $minutes minutes';
  }
}

const Map<int, double> seasonalBonusPercentageMap = {
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

const Map<int, double> ayrBonusPercentageMap = {
  1: 102.5,
  2: 105.0,
  3: 107.5,
  4: 110.0,
  5: 112.5,
  6: 115.0,
  7: 117.5,
  8: 120.0,
  9: 122.5,
  10: 125.0,
  11: 127.5,
  12: 130.0,
  13: 132.5,
  14: 135.0,
  15: 137.5,
  16: 140.0,
  17: 142.5,
  18: 145.0,
  19: 147.5,
  20: 150.0,
  21: 152.5,
  22: 155.0,
  23: 157.5,
  24: 160.0,
  25: 162.5,
  26: 165.0,
  27: 167.5,
  28: 170.0,
  29: 172.5,
  30: 175.0,
  31: 177.5,
  32: 180.0,
  33: 182.5,
  34: 185.0,
  35: 187.5,
  36: 190.0,
  37: 192.5,
  38: 195.0,
  39: 197.5,
  40: 200.0,
  41: 202.5,
  42: 205.0,
  43: 207.5,
  44: 210.0,
  45: 212.5,
};
