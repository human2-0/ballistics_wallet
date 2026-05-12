import 'dart:async';

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/custom_date_range.dart';
import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/ratio_and_bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/date_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class BonusInfoNotifier extends StateNotifier<BonusInfoAndRatio> {
  BonusInfoNotifier(this._repository, this.userId)
    : super(BonusInfoAndRatio()) {
    scheduleMicrotask(() async {
      await init();
      await loadBonusInfos(); // Add this line
    });
  }
  final BonusInfoRepository _repository;
  final String userId;
  Map<String, double> _productRatios = {};

  Future<void> init() async {
    // Fetch necessary data from the database
    final data = await _repository.getAllRatiosToday();

    // Update _productRatios directly with the fetched data
    // This replaces the existing map with the new one, whether it's empty or filled with ratios
    _productRatios = data;

    // Calculate the total ratio based on the updated _productRatios map
    final updatedRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);

    // Update the state with the new total ratio while preserving the current bonusInfo
    state = BonusInfoAndRatio(bonusInfo: state.bonusInfo, ratio: updatedRatio);
  }

  Future<void> refreshHive() async {
    await _repository.reopenBox();
  }

  void updateRatio(
    String productName,
    int productTarget,
    int userNumber,
    double workingHours,
    double allowanceProvided,
  ) {
    final productTargetAdjusted = adjustedProductTarget(
      productTarget: productTarget,
      workingHours: workingHours,
      allowanceProvided: allowanceProvided,
    );

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
    final updatedRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);
    state = BonusInfoAndRatio(bonusInfo: state.bonusInfo, ratio: updatedRatio);
  }

  int adjustedProductTarget({
    required int productTarget,
    required double workingHours,
    required double allowanceProvided,
  }) {
    if (workingHours <= 0) {
      return productTarget;
    }

    final workingTimeAfterAllowance = workingHours - allowanceProvided;
    if (workingTimeAfterAllowance <= 0) {
      return 0;
    }

    return (productTarget * (workingTimeAfterAllowance / workingHours)).ceil();
  }

  double calculateProductRatio({
    required int productTarget,
    required int userNumber,
    required double workingHours,
    required double allowanceProvided,
  }) {
    final productTargetAdjusted = adjustedProductTarget(
      productTarget: productTarget,
      workingHours: workingHours,
      allowanceProvided: allowanceProvided,
    );

    if (userNumber == 0 || productTargetAdjusted == 0) {
      return 0;
    }

    return userNumber / productTargetAdjusted.toDouble();
  }

  double getProductRatio(String productName) =>
      _productRatios[productName] ?? 0;

  Future<void> applyAllowanceToTodayEntries({
    required List<ProductInfo> products,
    required double workingHours,
    required double allowanceProvided,
  }) async {
    final today = DateTime.now();
    final productsByName = {
      for (final product in products)
        product.productName.toLowerCase().trim(): product,
    };
    var changed = false;

    final entries = await _repository.getAllBonusInfos();
    for (final entry in entries) {
      if (entry.isOvertime || !_isSameDay(entry.date, today)) {
        continue;
      }

      final updatedProduced = <Produced>[];
      var entryChanged = false;

      for (final produced in entry.produced) {
        final product =
            productsByName[produced.productName.toLowerCase().trim()];
        if (product == null) {
          updatedProduced.add(produced.copyWith(allowance: allowanceProvided));
          entryChanged =
              entryChanged || produced.allowance != allowanceProvided;
          continue;
        }

        final updatedRatio = calculateProductRatio(
          productTarget: product.target,
          userNumber: produced.amount,
          workingHours: workingHours,
          allowanceProvided: allowanceProvided,
        );
        updatedProduced.add(
          produced.copyWith(ratio: updatedRatio, allowance: allowanceProvided),
        );
        entryChanged =
            entryChanged ||
            produced.ratio != updatedRatio ||
            produced.allowance != allowanceProvided;
      }

      if (entryChanged) {
        await _repository.updateBonusInfo(
          entry.copyWith(produced: updatedProduced),
        );
        changed = true;
      }
    }

    if (changed) {
      await loadBonusInfos();
    }
  }

  bool _isSameDay(DateTime left, DateTime right) =>
      left.day == right.day &&
      left.month == right.month &&
      left.year == right.year;

  /// Returns all bonus entries for a given product, including date and amount.
  List<BonusInfo> getProductHistory(String productName) {
    final normalizedName = productName.toLowerCase().trim();
    if (normalizedName.isEmpty) {
      return const [];
    }
    return state.bonusInfo
        .where(
          (entry) => entry.produced.any(
            (p) => p.productName.toLowerCase().trim() == normalizedName,
          ),
        )
        .toList();
  }

  Future<void> loadBonusInfos() async {
    final box = await _repository.openBox(); // Ensure this method is accessible
    if (box.isEmpty) {
      // final bonuses = await _repository.fetchUserBonuses(userId);
      // Flatten the Map<DateTime, List<BonusInfo>> to a single List<BonusInfo>
      // final updatedBonusInfo = bonuses.values.expand((list) => list).toList();
      final ratio = await _repository.getAllRatiosToday();

      // Update _productRatios directly with the fetched data
      // This replaces the existing map with the new one, whether it's empty or filled with ratios
      _productRatios = ratio;

      //this is a placeholder for passing right updatedBonusInfo, but bool check already checked that its empty
      final updatedBonusInfo = box.values.toList();

      // Calculate the total ratio based on the updated _productRatios map
      final updatedRatio = _productRatios.values.fold<double>(
        0,
        (a, b) => a + b,
      );
      // Create a new state with the updated list
      state = BonusInfoAndRatio(
        bonusInfo: updatedBonusInfo,
        ratio: updatedRatio,
      );
    } else {
      // Use box values if not empty
      final updatedBonusInfo = box.values.toList();
      final ratio = await _repository.getAllRatiosToday();

      // Update _productRatios directly with the fetched data
      // This replaces the existing map with the new one, whether it's empty or filled with ratios
      _productRatios = ratio;

      // Calculate the total ratio based on the updated _productRatios map
      final updatedRatio = _productRatios.values.fold<double>(
        0,
        (a, b) => a + b,
      );
      // Create a new state with the updated list
      state = BonusInfoAndRatio(
        bonusInfo: updatedBonusInfo,
        ratio: updatedRatio,
      );
    }
  }

  Future<String> addBonusInfo(BonusInfo bonusInfo) async {
    final message = await _repository.addBonusInfo(bonusInfo);
    await loadBonusInfos(); // Reload the list after adding
    return message;
  }

  Future<void> updateBonusInfo(BonusInfo bonusInfo) async {
    await _repository.updateBonusInfo(bonusInfo);
    await loadBonusInfos(); // Reload the list after updating
  }

  Future<void> deleteBonusInfo(BonusInfo info) async {
    await _repository.deleteBonusInfo(info);
    await loadBonusInfos(); // Reload the list after deleting
  }

  Future<double> getTotalWorkingHours() async {
    // Try to read a persisted custom range from Hive
    final customRangeBox = await Hive.openBox<CustomDateRange>(
      'customDateRangeBox',
    ); // Await here!
    final customDateRange = customRangeBox.get('myCustomDateRange');
    if (customDateRange != null) {
      // If user has previously chosen a custom date range,
      // we prioritize that range for counting working hours
      final hoursStart = customDateRange.hoursStart;
      final hoursEnd = customDateRange.hoursEnd;
      if (hoursStart == null || hoursEnd == null) {
        // If either is null, fall back on default logic
        return _calculateDefaultHours();
      } else {
        return _calculateHoursInRange(hoursStart, hoursEnd);
      }
    } else {
      // No custom range found -> do your default 19th–18th logic
      return _calculateDefaultHours();
    }
  }

  double _calculateHoursInRange(DateTime start, DateTime end) {
    var total = 0.0;
    for (final bonusInfo in state.bonusInfo) {
      final date = bonusInfo.date;
      if (date.isAfterOrSame(start) && date.isBeforeOrSame(end)) {
        total += bonusInfo.workingHours;
      }
    }
    return total;
  }

  double _calculateDefaultHours() {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month, 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 19);
      endDate = DateTime(now.year, now.month, 18);
    }

    var total = 0.0;
    for (final bonusInfo in state.bonusInfo) {
      final date = bonusInfo.date;
      if (date.isAfterOrSame(startDate) && date.isBeforeOrSame(endDate)) {
        total += bonusInfo.workingHours;
      }
    }
    return total;
  }

  Future<double> getTotalBonus() async {
    // Check if a custom bonus range is present
    final customRangeBox = await Hive.openBox<CustomDateRange>(
      'customDateRangeBox',
    ); // Await here!
    final customDateRange = customRangeBox.get('myCustomDateRange');

    if (customDateRange != null) {
      final bonusStart = customDateRange.bonusStart;
      final bonusEnd = customDateRange.bonusEnd;
      if (bonusStart == null || bonusEnd == null) {
        return _calculateDefaultBonus();
      } else {
        return _calculateBonusInRange(bonusStart, bonusEnd);
      }
    } else {
      // fallback if none set
      return _calculateDefaultBonus();
    }
  }

  double _calculateBonusInRange(DateTime start, DateTime end) {
    var total = 0.0;
    for (final bonusInfo in state.bonusInfo) {
      final date = bonusInfo.date;
      if (date.isAfterOrSame(start) && date.isBeforeOrSame(end)) {
        total += bonusInfo.bonus;
      }
    }
    return total;
  }

  double _calculateDefaultBonus() {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month, 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 19);
      endDate = DateTime(now.year, now.month, 18);
    }

    var total = 0.0;
    for (final bonusInfo in state.bonusInfo) {
      final date = bonusInfo.date;
      if (date.isAfterOrSame(startDate) && date.isBeforeOrSame(endDate)) {
        total += bonusInfo.bonus;
      }
    }
    return total;
  }

  Future<List<MonthlyData>> getHistoricalMonthlyData() async =>
      buildMonthlyHistoricalData(bonusInfo: state.bonusInfo);
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final isOvertimeProvider = StateProvider<bool>((ref) => false);

final bonusInfoListProvider =
    StateNotifierProvider<BonusInfoNotifier, BonusInfoAndRatio>((ref) {
      final authRepo = ref.read(authRepositoryProvider);
      final userId = authRepo.currentUserId;
      final bonusInfoRepo = ref.read(bonusInfoRepositoryProvider);

      return BonusInfoNotifier(bonusInfoRepo, userId);
    });

final bonusInfoRepositoryProvider = Provider<BonusInfoRepository>((ref) {
  return BonusInfoRepository();
});

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  ref.watch(bonusInfoListProvider.select((s) => s.bonusInfo));
  final bonusNotifier = ref.read(bonusInfoListProvider.notifier);
  final hourlyRate =
      ref.watch(userNotifierProvider.select((s) => s.hourlyRate)) ?? 0;

  // 3️⃣  Do the maths *inside* the selected range.
  final results = await Future.wait([
    bonusNotifier.getTotalBonus(),
    bonusNotifier.getTotalWorkingHours(),
  ]);
  final totalBonus = results[0];
  final totalHours = results[1];
  final totalSalary = totalBonus + totalHours * hourlyRate;

  return WalletSummary(totalBonus, totalHours, totalSalary);
});

/// Simple model to hold summary data
class WalletSummary {
  const WalletSummary(this.totalBonus, this.totalHours, this.totalSalary);
  final double totalBonus;
  final double totalHours;
  final double totalSalary;
}

/// Builds paycheck-month summaries from wallet entries.
List<MonthlyData> buildMonthlyHistoricalData({
  required List<BonusInfo> bonusInfo,
  double hourlyRate = 0,
  DateTime? now,
}) {
  if (bonusInfo.isEmpty) {
    return const [];
  }

  final today = _historyDateOnly(now ?? DateTime.now());
  final monthAnchors = <DateTime>[_paycheckMonthForHours(today)];
  for (final info in bonusInfo) {
    monthAnchors
      ..add(_paycheckMonthForHours(info.date))
      ..add(_paycheckMonthForBonus(info.date));
  }
  monthAnchors.sort();

  var cursor = monthAnchors.first;
  final endMonth = monthAnchors.last;
  final historicalData = <MonthlyData>[];

  while (!_isAfterMonth(cursor, endMonth)) {
    final hoursStart = DateTime(cursor.year, cursor.month - 1, 20);
    final hoursEnd = DateTime(cursor.year, cursor.month, 19);
    final previousBonusEnd = bonusPayrollCloseDateForMonth(
      cursor.year,
      cursor.month - 1,
    );
    final bonusStart = previousBonusEnd.add(const Duration(days: 1));
    final bonusEnd = bonusPayrollCloseDateForMonth(cursor.year, cursor.month);

    var monthlyHours = 0.0;
    var monthlyBonus = 0.0;
    for (final info in bonusInfo) {
      final date = _historyDateOnly(info.date);
      if (_isWithinInclusive(date, hoursStart, hoursEnd)) {
        monthlyHours += info.workingHours;
      }
      if (_isWithinInclusive(date, bonusStart, bonusEnd)) {
        monthlyBonus += info.bonus;
      }
    }

    historicalData.add(
      MonthlyData.detailed(
        month: DateFormat('MMMM yyyy').format(cursor),
        totalHours: monthlyHours,
        totalBonus: monthlyBonus,
        hourlyRate: hourlyRate,
        hoursStart: hoursStart,
        hoursEnd: hoursEnd,
        bonusStart: bonusStart,
        bonusEnd: bonusEnd,
      ),
    );
    cursor = DateTime(cursor.year, cursor.month + 1);
  }

  return historicalData;
}

/// Returns the bonus payroll close date for a paycheck month.
DateTime bonusPayrollCloseDateForMonth(int year, int month) {
  var closeDate = DateTime(year, month, 18);
  while (_isWeekend(closeDate)) {
    closeDate = closeDate.subtract(const Duration(days: 1));
  }
  return closeDate;
}

DateTime _paycheckMonthForHours(DateTime date) {
  final cleanDate = _historyDateOnly(date);
  if (cleanDate.day >= 20) {
    return DateTime(cleanDate.year, cleanDate.month + 1);
  }
  return DateTime(cleanDate.year, cleanDate.month);
}

DateTime _paycheckMonthForBonus(DateTime date) {
  final cleanDate = _historyDateOnly(date);
  final closeDate = bonusPayrollCloseDateForMonth(
    cleanDate.year,
    cleanDate.month,
  );
  if (cleanDate.isAfter(closeDate)) {
    return DateTime(cleanDate.year, cleanDate.month + 1);
  }
  return DateTime(cleanDate.year, cleanDate.month);
}

bool _isWeekend(DateTime date) =>
    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

bool _isWithinInclusive(DateTime date, DateTime start, DateTime end) {
  final cleanDate = _historyDateOnly(date);
  final cleanStart = _historyDateOnly(start);
  final cleanEnd = _historyDateOnly(end);
  return !cleanDate.isBefore(cleanStart) && !cleanDate.isAfter(cleanEnd);
}

bool _isAfterMonth(DateTime month, DateTime other) =>
    month.year > other.year ||
    (month.year == other.year && month.month > other.month);

DateTime _historyDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

extension DateTimeExtensions on DateTime {
  /// Checks if this DateTime is at least (later than or the same as) another DateTime.
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}
