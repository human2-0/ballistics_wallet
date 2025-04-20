import 'package:ballistics_wallet_flutter/custom_widgets/animated_tiles.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BonusTableNotifier extends StateNotifier<BonusTableState> {
  BonusTableNotifier(this.ref) : super(BonusTableState()) {
    Future.microtask(() async => loadInitialData());
  }
  final Ref ref;

  Future<void> loadInitialData() async {
    try {
      final bonuses = getBonuses();
      final targetRatio = ref.watch(bonusInfoListProvider).ratio;
      final userData = ref.watch(userNotifierProvider);
      final overtimeRatio = ref.watch(overtimeRatioProvider);
      final overtimeHours = ref.watch(overtimeWorkingHoursState);
      final workingHours = userData.workingHours ?? 0.0;
      final allowance = ref.watch(allowanceProvider);
      final stableTarget = ref.watch(targetProvider);
      var target = stableTarget * (1 - targetRatio);
      final allowanceCheck = (workingHours - allowance) / 7;
      if (allowanceCheck > 0) {
        target = (target * allowanceCheck).ceilToDouble();
      }

      final listItems = calculateBonusItems(bonuses, targetRatio, overtimeRatio,
          overtimeHours, workingHours, allowance, stableTarget.toDouble(),);
      state = state.copyWith(
          isLoading: false, bonuses: bonuses, listItems: listItems,);
    } on FormatException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Map<String, dynamic> getBonuses() {
    final product = ref.read(focusedProductProvider);
    final check = product.ayr ?? false;
    if (check) {
      return ayrBonusPercentageMap
          .map((key, value) => MapEntry(value.toString(), key));
    } else {
      return seasonalBonusPercentageMap
          .map((key, value) => MapEntry(value.toString(), key));
    }
  }

  List<Widget> calculateBonusItems(
    Map<String, dynamic> bonuses,
    double targetRatio,
    double overtimeRatio,
    double? overtimeHours,
    double workingHours,
    double allowance,
    double stableTarget,
  ) {
    final items = <Widget>[];
    final bonusData = <BonusItem>[];

    final sortedKeys = bonuses.keys.toList()..sort();
    var target = stableTarget * (1 - targetRatio);
    final allowanceCheck = (workingHours - allowance) / 7;
    if (allowanceCheck > 0) {
      target = (target * allowanceCheck).ceilToDouble();
    }

    if (targetRatio * 100 >= 212.5) {
      items.add(
        Container(
          margin: const EdgeInsets.all(16),
          width: double.infinity, // Assuming full width is desired for layout
          height: 200, // Adjust height as needed
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.orange[200]!, Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.orange.withOpacity(0.5),
                gradient: LinearGradient(
                  colors: [Colors.orange[200]!, Colors.white],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 3,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Congrats,\nyou have achieved maximum bonus!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      if (target > 0) {
        items.add(
          MinimumAnimatedTile(
            target: target.ceil(),
            onLongPressComplete:
                () {}, // Callback needs context and ref, handle outside
          ),
        );
      }

      for (final key in sortedKeys) {
        final bonus = (bonuses[key] as num).toDouble() *
            (overtimeHours != null && overtimeHours > 0
                ? overtimeHours / 7
                : allowanceCheck);
        final requiredPercentage = double.parse(key) -
            (overtimeRatio > 0.0 ? overtimeRatio : targetRatio) * 100;
        final requiredAmount = ((requiredPercentage *
                    (allowanceCheck > 0
                        ? (stableTarget * allowanceCheck).ceil()
                        : stableTarget)) /
                100)
            .ceil();

        if (requiredAmount > 0) {
          items.add(
            BonusAnimatedTile(
              bonus: bonus,
              requiredAmount: requiredAmount,
              onLongPressComplete:
                  () {}, // Callback needs context and ref, handle outside
            ),
          );
          bonusData.add(BonusItem(
              bonus: bonus,
              requiredAmount: requiredAmount,),); // Collect each item
        }
      }
    }
    state = state.copyWith(bonusData: [...?state.bonusData, ...bonusData]);

    return items;
  }
}

class BonusTableState {
  BonusTableState({
    this.bonuses,
    this.isLoading = true,
    this.errorMessage,
    this.listItems = const [],
    this.bonusData = const [],
  });
  final Map<String, dynamic>? bonuses;
  final List<Widget>? listItems;
  final bool isLoading;
  final String? errorMessage;
  final List<BonusItem>? bonusData;

  BonusTableState copyWith({
    Map<String, dynamic>? bonuses,
    List<Widget>? listItems,
    bool? isLoading,
    String? errorMessage,
    List<BonusItem>? bonusData,
  }) =>
      BonusTableState(
        bonuses: bonuses ?? this.bonuses,
        listItems: listItems ?? this.listItems,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
        bonusData: bonusData ?? this.bonusData,
      );
}

class BonusItem {
  BonusItem({required this.bonus, required this.requiredAmount});
  final double bonus;
  final int requiredAmount;
}

final bonusTableProvider =
    StateNotifierProvider<BonusTableNotifier, BonusTableState>(
        BonusTableNotifier.new,);
