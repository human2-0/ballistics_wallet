// Timeline providers are shared inside the app and are not package API.
// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/work_timeline_plan.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const _workTimelineSettingsBox = 'work_timeline_settings';
const _targetBonusKey = 'targetBonus';
const _breakReminderKey = 'breakReminderEnabled';
const _batchReminderKey = 'batchReminderEnabled';

class WorkTimelineSettings {
  const WorkTimelineSettings({
    this.targetBonus = 0,
    this.breakReminderEnabled = false,
    this.batchReminderEnabled = false,
  });

  final double targetBonus;
  final bool breakReminderEnabled;
  final bool batchReminderEnabled;

  WorkTimelineSettings copyWith({
    double? targetBonus,
    bool? breakReminderEnabled,
    bool? batchReminderEnabled,
  }) => WorkTimelineSettings(
    targetBonus: targetBonus ?? this.targetBonus,
    breakReminderEnabled: breakReminderEnabled ?? this.breakReminderEnabled,
    batchReminderEnabled: batchReminderEnabled ?? this.batchReminderEnabled,
  );
}

class WorkTimelineSettingsNotifier extends StateNotifier<WorkTimelineSettings> {
  WorkTimelineSettingsNotifier() : super(const WorkTimelineSettings()) {
    scheduleMicrotask(_load);
  }

  Future<void> _load() async {
    final box = await Hive.openBox<dynamic>(_workTimelineSettingsBox);
    final target = box.get(_targetBonusKey);
    final breakReminder = box.get(_breakReminderKey);
    final batchReminder = box.get(_batchReminderKey);

    state = WorkTimelineSettings(
      targetBonus: target is num ? target.toDouble() : 0,
      breakReminderEnabled: breakReminder is bool && breakReminder,
      batchReminderEnabled: batchReminder is bool && batchReminder,
    );
  }

  Future<void> setTargetBonus(double value) async {
    final next = value < 0 ? _zeroDouble() : value;
    state = state.copyWith(targetBonus: next);
    final box = await Hive.openBox<dynamic>(_workTimelineSettingsBox);
    await box.put(_targetBonusKey, next);
  }

  Future<void> setBreakReminderEnabled(bool value) async {
    state = state.copyWith(breakReminderEnabled: value);
    final box = await Hive.openBox<dynamic>(_workTimelineSettingsBox);
    await box.put(_breakReminderKey, value);
  }

  Future<void> setBatchReminderEnabled(bool value) async {
    state = state.copyWith(batchReminderEnabled: value);
    final box = await Hive.openBox<dynamic>(_workTimelineSettingsBox);
    await box.put(_batchReminderKey, value);
  }
}

final workTimelineSettingsProvider =
    StateNotifierProvider<WorkTimelineSettingsNotifier, WorkTimelineSettings>(
      (ref) => WorkTimelineSettingsNotifier(),
    );

final workTimelinePlanProvider = Provider.autoDispose.family<
  WorkTimelinePlan,
  DateTime
>((ref, now) {
  final settings = ref.watch(workTimelineSettingsProvider);
  final bonusState = ref.watch(bonusInfoListProvider);
  final userState = ref.watch(userNotifierProvider);
  final focusedProduct = ref.watch(focusedProductProvider);
  final perBatch = ref.watch(amountPerBatchProvider);
  final allowance = ref.watch(allowanceProvider);
  final typedAmount = int.tryParse(ref.watch(numberControllerProvider)) ?? 0;

  final savedProgress = _todayProgressForProduct(
    bonusState.bonusInfo,
    focusedProduct,
    now,
  );
  final productTarget = focusedProduct.target;
  final workingHours = userState.workingHours ?? 0;
  final ratioFromTypedAmount = _ratioForAmount(
    amount: typedAmount,
    productTarget: productTarget,
    workingHours: workingHours,
    allowance: allowance,
  );
  final liveRatio =
      ratioFromTypedAmount > savedProgress.ratio
          ? ratioFromTypedAmount
          : savedProgress.ratio;
  final adjustedTarget = _adjustedProductTarget(
    productTarget: productTarget,
    workingHours: workingHours,
    allowance: allowance,
  );
  final equivalentAmountMade =
      adjustedTarget > 0 ? (liveRatio * adjustedTarget).floor() : 0;
  final directAmountMade =
      savedProgress.amount > typedAmount ? savedProgress.amount : typedAmount;
  final amountMade =
      directAmountMade > equivalentAmountMade
          ? directAmountMade
          : equivalentAmountMade;

  return WorkTimelinePlan.calculate(
    now: now,
    targetBonus: settings.targetBonus,
    currentRatio: liveRatio,
    useAyrBonusTable: focusedProduct.ayr ?? true,
    productTarget: productTarget,
    amountMade: amountMade,
    perBatch: perBatch,
    workingHours: workingHours,
    allowance: allowance,
  );
});

_ProductProgress _todayProgressForProduct(
  List<BonusInfo> entries,
  ProductInfo product,
  DateTime now,
) {
  final productName = product.productName.toLowerCase().trim();
  if (productName.isEmpty) return const _ProductProgress();

  var amount = 0;
  var ratio = 0.0;
  for (final entry in entries) {
    if (entry.isOvertime || !_isSameDay(entry.date, now)) continue;
    for (final produced in entry.produced) {
      if (produced.productName.toLowerCase().trim() == productName) {
        amount = math.max(amount, produced.amount);
        ratio = math.max(ratio, produced.ratio);
      }
    }
  }
  return _ProductProgress(amount: amount, ratio: ratio);
}

double _ratioForAmount({
  required int amount,
  required int productTarget,
  required double workingHours,
  required double allowance,
}) {
  if (amount <= 0 || productTarget <= 0) return 0;
  final adjustedTarget = _adjustedProductTarget(
    productTarget: productTarget,
    workingHours: workingHours,
    allowance: allowance,
  );
  if (adjustedTarget <= 0) return 0;
  return amount / adjustedTarget;
}

int _adjustedProductTarget({
  required int productTarget,
  required double workingHours,
  required double allowance,
}) {
  if (workingHours <= 0) return productTarget;
  final effectiveHours = workingHours - allowance;
  if (effectiveHours <= 0) return 0;
  return (productTarget * (effectiveHours / workingHours)).ceil();
}

bool _isSameDay(DateTime left, DateTime right) =>
    left.day == right.day &&
    left.month == right.month &&
    left.year == right.year;

class _ProductProgress {
  const _ProductProgress({this.amount = 0, this.ratio = 0});

  final int amount;
  final double ratio;
}

double _zeroDouble() => 0;
