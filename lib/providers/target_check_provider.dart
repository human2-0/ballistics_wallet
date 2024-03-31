import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final numberFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final numberFocusNode = FocusNode();
  ref.onDispose(numberFocusNode.dispose);
  return numberFocusNode;
});

final allowanceFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final allowanceFocusNode = FocusNode();
  ref.onDispose(allowanceFocusNode.dispose);
  return allowanceFocusNode;
});

final showListProvider = StateProvider<bool>((ref) => false);

final focusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final focusNode = FocusNode();
  final focusNotifier = ref.read(focusNotifierProvider.notifier);

  focusNode.addListener(() {
    focusNotifier.setFocus(focusNode.hasFocus);
  });

  ref.onDispose(() {
    focusNode
      ..removeListener(() {
        focusNotifier.setFocus(focusNode.hasFocus);
      })
      ..dispose();
  });

  return focusNode;
});

final focusNotifierProvider =
    StateNotifierProvider<FocusNotifier, bool>((ref) => FocusNotifier());

final textEditingControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final numberProvider = StateProvider<int>((ref) => 0);

final targetProvider =
    StateProvider<int>((ref) => 0);

final allowanceProvider = StateProvider<double>((ref) => 0.0);

final overtimeRatioProvider = StateProvider<double>((ref) => 0.0);
final overtimeWorkingHoursState = StateProvider<int?>((ref) => 0);

final productsProvider =
    FutureProvider.autoDispose<List<ProductInfo>>((ref) async {
  final productsList = ref.watch(productInfoProvider);
  return productsList;
});

final bonusCalculator = Provider.family<double, double>((ref, targetRatio) {
  targetRatio *= 100; // Convert targetRatio to percentage
  final workingHours = ref.read(userNotifierProvider).workingHours ?? 0;
  final allowance = ref.read(userNotifierProvider).workingHours ?? 0;

  // Sort the keys in ascending order
  final sortedKeys = bonusPercentageMap.keys.toList()
    ..sort((a, b) => b.compareTo(a)); // We sort in descending order

  var bonus = 0.0;
  for (final key in sortedKeys) {
    // Check the logic

    if (targetRatio >= (bonusPercentageMap[key] ?? 0)) {
      bonus = key * (workingHours - allowance / 7);
      bonus = key.toDouble();
      break;
    }
  }
  return bonus;
});

final lastSelectedProductProvider =
    StateNotifierProvider<LastSelectedProductNotifier, List<SelectedProduct>>(
  (ref) => LastSelectedProductNotifier(),
);
