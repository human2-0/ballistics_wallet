import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
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
    focusNode..removeListener(() {
      focusNotifier.setFocus(focusNode.hasFocus);
    })
    ..dispose();
  });

  return focusNode;
});

final focusNotifierProvider = StateNotifierProvider<FocusNotifier, bool>((ref) => FocusNotifier());



final textEditingControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  return controller;
});


// Similarly for other controllers
final numberControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final allowanceControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

final targetRatioProvider = StateNotifierProvider.autoDispose
    .family<TargetRatioNotifier, double, String>((ref, userId) => TargetRatioNotifier(ref.watch(pressingRepositoryProvider), userId));

final numberProvider = StateProvider< int>((ref) => 0);

final targetProvider =
    StateNotifierProvider<TargetNotifier, int>((ref) => TargetNotifier());

final allowanceProvider = StateProvider<double>((ref) => 0.0);

final overtimeRatioProvider = StateProvider<double>((ref) => 0.0);
final overtimeWorkingHoursState = StateProvider<int?>((ref) => 0);

final monthlyWorkingHoursProvider = StateProvider<double>((ref) => 0.0);

final searchTermProvider = StateProvider<String>((ref) {
  // Watch the lastSelectedProductProvider
  final lastSelectedProducts = ref.watch(lastSelectedProductProvider);

  // Return the name of the first product if the list is not empty, otherwise return an empty string
  return lastSelectedProducts.isNotEmpty ? lastSelectedProducts.last.name : '';
});

final selectedProductProvider = StateProvider<StateController<String>>((ref) {
  // Watch the lastSelectedProductProvider
  final lastSelectedProducts = ref.watch(lastSelectedProductProvider);

  // Initialize the StateController with the name of the first product if the list is not empty, otherwise use an empty string
  return StateController<String>(
    lastSelectedProducts.isNotEmpty ? lastSelectedProducts[0].name : '',
  );
});


final productsMade = StateProvider<int>((ref) => 0);

final userBonusesProvider =
StateNotifierProvider<UserBonusesNotifier, Map<DateTime, List<dynamic>>>(
        (ref) => UserBonusesNotifier(),);



final productUpdateProvider =
StateNotifierProvider<ProductUpdateNotifier, bool>((ref) => ProductUpdateNotifier());

class ProductUpdateNotifier extends StateNotifier<bool> {
  ProductUpdateNotifier() : super(false);

  void update() {
    state = !state;
  }
}

final productsProvider = FutureProvider.autoDispose
    .family<List<ProductInfo>, bool>((ref, updated) async {
  final productsList = ref.watch(productInfoProvider);
  return productsList;
});

final bonusValueProvider = Provider.family<double, double>((ref, targetRatio) {
  targetRatio *= 100; // Convert targetRatio to percentage

  // Check the input

  // Sort the keys in ascending order
  final sortedKeys = bonusPercentageMap.keys.toList()
    ..sort((a, b) => b.compareTo(a)); // We sort in descending order

  var bonus = 0.0;
  for (final key in sortedKeys) {
    // Check the logic

    if (targetRatio >= (bonusPercentageMap[key] ?? 0)) {
      bonus = key.toDouble();
      break;
    }
  }

  // Check the output

  return bonus;
});

final lastSelectedProductProvider = StateNotifierProvider<LastSelectedProductNotifier, List<SelectedProduct>>(
      (ref) => LastSelectedProductNotifier(),
);
