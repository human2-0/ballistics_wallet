import 'dart:async';

import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
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
      double workingHours, double allowanceProvided) {
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

  void updateNumber(int newNumber) {
    state = newNumber;
  }
}

class TargetNotifier extends StateNotifier<int> {
  TargetNotifier() : super(0);

  void updateTarget(int newTarget) {
    state = newTarget;
  }
}

class FocusNotifier extends StateNotifier<bool> {
  FocusNotifier() : super(false);

  void setFocus(bool focus) {
    state = focus;
  }
}

class UserBonusesNotifier extends StateNotifier<Map<DateTime, List<dynamic>>> {
  UserBonusesNotifier() : super({});

  void setUserBonuses(Map<DateTime, List<dynamic>> userBonuses) {
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
    Future.microtask(_fetchInitialData);
  }

  Future<void> _fetchInitialData() async {
    // Set state to a loading state if you have one, otherwise skip this step
    // state = LoadingState();

    final box = await Hive.openBox<SelectedProduct>('selected_products');
    final products = box.values.toList();
    state = products;
  }

  Future<void> saveSelectedProduct(SelectedProduct product) async {
    final box = await Hive.openBox<SelectedProduct>('selected_products');

    // Try to find an existing product with the same name
    final existingProductKey = box.keys.firstWhere(
      (key) => box.get(key)!.name == product.name,
      orElse: () => null,
    );

    if (existingProductKey != null) {
      // If found, update the existing product's selectedDate
      final existingProduct = box.get(existingProductKey);
      final updatedProduct = SelectedProduct(
        name: existingProduct!.name,
        selectedDate: DateTime.now(),
        target: existingProduct.target,
      );
      await box.put(existingProductKey, updatedProduct);
    } else {
      // If not found, add the new product to the box
      await box.add(product);
    }

    // Update the state with the latest values
    state = box.values.toList();
  }

  Future<void> deleteSelectedProductByName(String productName) async {
    final box = await Hive.openBox<SelectedProduct>('selected_products');

    // Try to find the key of the product with the given name
    final productKey = box.keys.firstWhere(
      (key) => box.get(key)!.name == productName,
      orElse: () => null,
    );

    if (productKey != null) {
      // If found, delete the product from the box
      await box.delete(productKey);
    } else {
      print('Product not found!');
    }

    // Update the state with the latest values
    state = box.values.toList();
  }

  Future<void> fetchLast7SelectedProducts() async {
    final box = await Hive.openBox<SelectedProduct>('selected_products');
    final last7Products = box.values.toList()
      ..sort((a, b) => b.selectedDate.compareTo(a.selectedDate));
    state = last7Products.take(7).toList();
  }
}
