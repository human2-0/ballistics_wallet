import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_db_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class TargetRatioNotifier extends StateNotifier<double> {

  TargetRatioNotifier(this._repository, this._userId) : super(0) {
    Future.microtask(init);
  }
  final PressingRepository _repository;
  final String _userId;
  Map<String, double> _productRatios = {};

  Future<void> init() async {
    // Fetch necessary data from database
    final data =
        await _repository.getUserProductInfo(_userId);
    if (data.isEmpty) {
      _productRatios = {};
    }

    // Ensure that the notifier has not been disposed of before continuing.
    // StateNotifier.mounted returns a bool that is true if the notifier has not been disposed of.
    if (!mounted) return;

    // Store the data in the _productRatios map
    _productRatios = data.map((key, value) => MapEntry(key, value as double));

    // Calculate the total ratio and update the state
    state = _productRatios.values.fold(0, (a, b) => a + b);
  }

  void updateRatio(String productName, int productTarget, int userNumber,
      double workingHours, double allowanceProvided,) {
    int productTargetAdjusted;

    // If workingHours are equal to 8, adjust productTarget with respect to workingHours and allowance
    if (workingHours == 8) {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / 7.00)).ceil();
    }
    // If workingHours are less than 8, adjust productTarget only with respect to allowance
    else {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / workingHours))
              .ceil();
    }

    // Handle zero cases
    if (userNumber == 0 || productTargetAdjusted == 0) {
      // If this product is already in the map, remove it
      _productRatios.remove(productName);
    } else {
      // Calculate the ratio
      final newRatio = userNumber / productTargetAdjusted.toDouble();

      // Update the map
      _productRatios[productName] = newRatio;
    }

    // Recalculate the total ratio and update the state
    state = _productRatios.values.fold(0, (a, b) => a + b);
  }

  double getProductRatio(String productName) => _productRatios[productName] ?? 0;
}

class NumberNotifier extends StateNotifier<int> {
  NumberNotifier() : super(0);

  Future<void> updateNumber(int newNumber) async {
    state = newNumber;
  }
}

class TargetNotifier extends StateNotifier<int> {
  TargetNotifier() : super(0);

  Future<void> updateTarget(int newTarget) async => state = newTarget;
}

class FocusNotifier extends StateNotifier<bool> {
  FocusNotifier() : super(false);

  Future<void> setFocus(bool focus) async {
    state = focus;
  }
}

class UserBonusesNotifier extends StateNotifier<Map<DateTime, List<dynamic>>> {
  UserBonusesNotifier() : super({});

  Future<void> setUserBonuses(Map<DateTime, List<dynamic>> userBonuses) async {
    state = userBonuses;
  }

  int calculateMonthlyBonus() {
    final now = DateTime.now();

    // if today is before the 20th, count from the 20th of the previous month
    // otherwise, count from the 20th of this month
    final startMonth = now.day < 20 ? now.month - 1 : now.month;
    final startYear =
        now.month == 1 && startMonth == 12 ? now.year - 1 : now.year;

    final start = DateTime(startYear, startMonth, 19);
    final end = DateTime(startYear, startMonth + 1, 18);

    var totalBonus = 0;

    for (final entry in state.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (final bonus in bonuses) {
          final bonusValue = bonus['bonus'];
          if (bonusValue is num) {
            totalBonus += bonusValue.round();
          }
        }
      }
    }

    return totalBonus;
  }
}

class LastSelectedProductNotifier extends StateNotifier<List<SelectedProduct>> {
  LastSelectedProductNotifier() : super([]) {
    Future.microtask(_initBoxes);
  }

  Future<void> _initBoxes() async {
    // Assuming Hive is initialized and SelectedProduct adapter is registered elsewhere
    await Hive.openBox<SelectedProduct>('selected_products');
    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final box = Hive.box<SelectedProduct>('selected_products');
    // Products are already sorted by date due to the box's structure
    final products = box.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    state = products;
  }

  Future<void> saveSelectedProduct(ProductInfo productInfo) async {
    final box = Hive.box<SelectedProduct>('selected_products');
    final productKey = box.values.firstWhere(
          (item) => item.productInfo.productName == productInfo.productName,
      orElse: () => SelectedProduct(date: DateTime.now(), productInfo: productInfo),
    )?.key;
    if (productKey != null) {
      await box.delete(productKey);}
    final selectedProduct = SelectedProduct(
      date: DateTime.now(),
      productInfo: productInfo,
    );
    // Since DateTime.now() is used as a key, ensure uniqueness or handle potential collisions
    await box.add(selectedProduct); // Using add as we don't need to specify a key

    await _fetchInitialData();
  }

  Future<void> deleteSelectedProductByName(String productName) async {
    final box = Hive.box<SelectedProduct>('selected_products');
    // Find and delete the product by name
    final productKey = box.values.firstWhere(
          (item) => item.productInfo.productName == productName,
      orElse: () => SelectedProduct(date: DateTime.now(), productInfo: ProductInfo(productName: '', imageName: '', target: 0, product: [])),
    )?.key;

    if (productKey != null) {
      await box.delete(productKey);
      await _fetchInitialData();
    }
  }
}
