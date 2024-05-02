import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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

class AllowanceNotifier extends StateNotifier<double> {

  AllowanceNotifier(this.ref) : super(0) {
    Future.microtask(_fetchInitialAllowance);
  }
  final Ref ref;

  Future<void> _fetchInitialAllowance() async {
    try {
      final box = Hive.box<BonusInfo>('bonusInfoBox');
      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final bonusInfoToday = box.values.firstWhere(
            (bonusInfo) => DateFormat('yyyy-MM-dd').format(bonusInfo.date) == todayString,
        orElse: () => BonusInfo(userId: 'userId', bonus: 0, date: DateTime(1), workingHours: 0, isOvertime: false, produced: [Produced(amount: 0,productName: '',ratio: 0)]),
      );

      if (bonusInfoToday.produced.isNotEmpty) {
        final producedToday = bonusInfoToday.produced.firstWhere(
              (prod) => prod.allowance != null,
          orElse: () => Produced(productName: '', amount: 0, ratio: 0),
        );
        state = producedToday.allowance ?? 0;
      }

    } on FormatException catch (e) {
      // Handle errors or log them
    }
  }

  void updateAllowance(double newAllowance) {
    if (newAllowance >= 0) {  // Example validation: allowance should not be negative
      state = newAllowance;
    } else {
    }
  }
}

final allowanceProvider = StateNotifierProvider<AllowanceNotifier, double>((ref) {
  return AllowanceNotifier(ref);
});

final overtimeRatioProvider = StateProvider<double>((ref) => 0.0);
final overtimeWorkingHoursState = StateProvider<double?>((ref) => 0.0);

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
