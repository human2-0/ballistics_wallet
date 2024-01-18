import 'package:ballistics_wallet_flutter/models/product_name.dart';
import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_db_repository.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

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

final selectedProductFromHiveProvider = FutureProvider<String>((ref) async {
  final box = await Hive.openBox('settings');
  // Use `as String?` to cast the result to a nullable String
  final result = box.get('selectedProduct', defaultValue: '') as String?;
  // Return the result if it's not null, otherwise return an empty string
  return result ?? '';
});


final textEditingControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final textValueFromHive = ref.watch(selectedProductFromHiveProvider);
  final controller = TextEditingController(
      text: textValueFromHive.maybeWhen(data: (data) => data, orElse: () => ''),
  );
  controller.addListener(() {
    ref.read(searchTermProvider.notifier).state = controller.text;
  });
  ref.onDispose(controller.dispose);
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
  final searchTermFromHive = ref.watch(selectedProductFromHiveProvider);
  return searchTermFromHive.maybeWhen(data: (data) => data, orElse: () => '');
});

final selectedProductProvider = StateProvider<StateController<String>>((ref) {
  final selectedProductFromHive = ref.watch(selectedProductFromHiveProvider);
  return StateController<String>(
      selectedProductFromHive.maybeWhen(data: (data) => data, orElse: () => ''),
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
    .family<List<ProductName>, bool>((ref, updated) async {
  final repository = ref.read(pressingRepositoryProvider);
  final products = await repository.readProductsPressing();
  return products;
});

final imageNameProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, productName) async {
  final repository = ref.read(pressingRepositoryProvider);
  final imageName = await repository.getImageNameForProduct(productName);
  return imageName;
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
