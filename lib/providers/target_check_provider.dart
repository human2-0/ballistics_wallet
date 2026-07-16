// Providers in this file are app state, not package API.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
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

enum ProductListSource { lastSelected, allProducts }

final productListSourceProvider = StateProvider<ProductListSource>(
  (ref) => ProductListSource.lastSelected,
);

enum ProductEffortFilter { none, leastEffort, maxEffort }

final productEffortFilterProvider = StateProvider<ProductEffortFilter>(
  (ref) => ProductEffortFilter.none,
);

final focusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final focusNode = FocusNode();
  final focusNotifier = ref.read(focusNotifierProvider.notifier);

  void handleFocusChange() {
    final hasFocus = focusNode.hasFocus;
    scheduleMicrotask(() => focusNotifier.setFocus(hasFocus));
  }

  focusNode.addListener(handleFocusChange);

  ref.onDispose(() {
    focusNode
      ..removeListener(handleFocusChange)
      ..dispose();
  });

  return focusNode;
});

void openProductLookup(WidgetRef ref) {
  ref.read(numberFocusNodeProvider).unfocus();
  ref.read(allowanceFocusNodeProvider).unfocus();
  // Keep this as the logical default even while the asynchronously loaded
  // history is still empty. The list UI falls back to all products when there
  // is no history, then switches to last selected if history finishes loading.
  ref.read(productListSourceProvider.notifier).state =
      ProductListSource.lastSelected;
  ref.read(showListProvider.notifier).state = true;
}

void dismissTargetCheckInputs(WidgetRef ref, {bool hideProductList = true}) {
  FocusManager.instance.primaryFocus?.unfocus();
  ref.read(focusNodeProvider).unfocus();
  ref.read(numberFocusNodeProvider).unfocus();
  ref.read(allowanceFocusNodeProvider).unfocus();
  if (hideProductList) {
    ref.read(showListProvider.notifier).state = false;
  }
}

final focusNotifierProvider = StateNotifierProvider<FocusNotifier, bool>(
  (ref) => FocusNotifier(),
);

final textEditingControllerProvider =
    Provider.autoDispose<TextEditingController>((ref) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });

final numberProvider = StateProvider<int>((ref) => 0);

final targetProvider = StateProvider<int>((ref) => 0);

class AllowanceNotifier extends StateNotifier<double> {
  AllowanceNotifier(this.ref) : super(0) {
    scheduleMicrotask(_fetchInitialAllowance);
  }
  final Ref ref;
  Future<void> _pendingPersistence = Future<void>.value();

  Future<void> _fetchInitialAllowance() async {
    try {
      if (!Hive.isBoxOpen('bonusInfoBox')) {
        return;
      }
      final box = Hive.box<BonusInfo>('bonusInfoBox');
      final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final bonusInfoToday = box.values.firstWhere(
        (bonusInfo) =>
            DateFormat('yyyy-MM-dd').format(bonusInfo.date) == todayString,
        orElse:
            () => BonusInfo(
              userId: 'userId',
              bonus: 0,
              date: DateTime(1),
              workingHours: 0,
              isOvertime: false,
              produced: [Produced(amount: 0, productName: '', ratio: 0)],
            ),
      );

      if (bonusInfoToday.produced.isNotEmpty) {
        final producedToday = bonusInfoToday.produced.firstWhere(
          (prod) => prod.allowance != null,
          orElse: () => Produced(productName: '', amount: 0, ratio: 0),
        );
        state = producedToday.allowance ?? 0;
      }
    } on Object catch (_) {
      // Handle errors or log them
    }
  }

  void setAllowance(double newAllowance) {
    if (newAllowance < 0 || state == newAllowance) return;
    state = newAllowance;
  }

  Future<void> persistAllowance(double newAllowance) {
    if (newAllowance < 0) return Future<void>.value();

    final previousPersistence = _pendingPersistence;
    return _pendingPersistence = _persistAfter(
      previousPersistence,
      newAllowance,
    );
  }

  Future<void> _persistAfter(
    Future<void> previousPersistence,
    double newAllowance,
  ) async {
    try {
      await previousPersistence;
    } on Object catch (_) {
      // A failed write must not poison the queue for later edits.
    }
    // A newer edit supersedes this queued value before it reaches storage.
    if (state != newAllowance) return;
    try {
      final userState = ref.read(userNotifierProvider);
      await ref
          .read(bonusInfoListProvider.notifier)
          .applyAllowanceToTodayEntries(
            products: ref.read(productInfoProvider),
            workingHours: userState.workingHours ?? 0.0,
            allowanceProvided: newAllowance,
          );
    } on Object catch (error) {
      debugPrint('Failed to persist allowance: $error');
    }
  }

  Future<void> updateAllowance(double newAllowance) {
    setAllowance(newAllowance);
    return persistAllowance(newAllowance);
  }
}

final allowanceProvider = StateNotifierProvider<AllowanceNotifier, double>(
  AllowanceNotifier.new,
);

final overtimeRatioProvider = StateProvider<double>((ref) => 0.0);
final overtimeWorkingHoursState = StateProvider<double?>((ref) => 0.0);

final productsProvider = FutureProvider.autoDispose<List<ProductInfo>>((ref) {
  final productsList = ref.watch(productInfoProvider);
  return productsList;
});

final bonusCalculator = Provider.family<double, double>((ref, targetRatio) {
  final targetPercentage = targetRatio * 100;
  final workingHours = ref.read(userNotifierProvider).workingHours ?? 0;
  final allowance = ref.read(userNotifierProvider).workingHours ?? 0;
  final product = ref.read(focusedProductProvider).ayr ?? true;

  // Sort the keys in ascending order
  if (product) {
    final sortedKeys =
        ayrBonusPercentageMap.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // We sort in descending order
    var bonus = 0.0;
    for (final key in sortedKeys) {
      // Check the logic

      if (targetPercentage >= (ayrBonusPercentageMap[key] ?? 0)) {
        bonus = key * (workingHours - allowance / 7);
        bonus = key.toDouble();
        break;
      }
    }
    return bonus;
  } else {
    final sortedKeys =
        seasonalBonusPercentageMap.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // We sort in descending order
    var bonus = 0.0;
    for (final key in sortedKeys) {
      // Check the logic

      if (targetPercentage >= (seasonalBonusPercentageMap[key] ?? 0)) {
        bonus = key * (workingHours - allowance / 7);
        bonus = key.toDouble();
        break;
      }
    }
    return bonus;
  }
});

final lastSelectedProductProvider =
    StateNotifierProvider<LastSelectedProductNotifier, List<SelectedProduct>>(
      (ref) => LastSelectedProductNotifier(),
    );
