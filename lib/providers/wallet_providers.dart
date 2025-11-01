import 'dart:async';

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/custom_date_range.dart';
import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
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
    var productTargetAdjusted = 0;

    // If workingHours are equal to 8, adjust productTarget with respect to workingHours and allowance
    if (workingHours > 0) {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / workingHours))
              .ceil();
    } else {
      if (workingHours == 0) {
        productTargetAdjusted = productTarget;
      }
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
    final updatedRatio = _productRatios.values.fold<double>(0, (a, b) => a + b);
    state = BonusInfoAndRatio(bonusInfo: state.bonusInfo, ratio: updatedRatio);
  }

  double getProductRatio(String productName) =>
      _productRatios[productName] ?? 0;

  /// Returns all bonus entries for a given product, including date and amount.
  List<BonusInfo> getProductHistory(String productName) {
    final needle = productName.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return state.bonusInfo.where((entry) {
      return entry.produced.any((p) {
        final name = p.productName.trim().toLowerCase();
        return name == needle;
      });
    }).toList();
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
      final updatedRatio =
          _productRatios.values.fold<double>(0, (a, b) => a + b);
      // Create a new state with the updated list
      state =
          BonusInfoAndRatio(bonusInfo: updatedBonusInfo, ratio: updatedRatio);
    } else {
      // Use box values if not empty
      final updatedBonusInfo = box.values.toList();
      final ratio = await _repository.getAllRatiosToday();

      // Update _productRatios directly with the fetched data
      // This replaces the existing map with the new one, whether it's empty or filled with ratios
      _productRatios = ratio;

      // Calculate the total ratio based on the updated _productRatios map
      final updatedRatio =
          _productRatios.values.fold<double>(0, (a, b) => a + b);
      // Create a new state with the updated list
      state =
          BonusInfoAndRatio(bonusInfo: updatedBonusInfo, ratio: updatedRatio);
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

  Future<List<MonthlyData>> getHistoricalMonthlyData() async {
    final historicalData = <MonthlyData>[];
    final endDate = DateTime.now();
    var startDate = state.bonusInfo.isNotEmpty
        ? state.bonusInfo
            .map((b) => b.date)
            .reduce((a, b) => a.isBefore(b) ? a : b)
        : DateTime.now().subtract(const Duration(days: 365));

    // This logic ensures you continue until the current month's data is processed fully
    while (startDate.year < endDate.year ||
        (startDate.year == endDate.year && startDate.month <= endDate.month)) {
      // Define month range based on the 19th to the 18th span
      final monthStart = DateTime(startDate.year, startDate.month, 19);
      final monthEnd = DateTime(startDate.year, startDate.month + 1, 18);

      var monthlyHours = 0.0;
      var monthlyBonus = 0.0;
      for (final bonusInfo in state.bonusInfo) {
        // Check if the date is within the current range, inclusive of both start and end
        if (bonusInfo.date.isAtLeast(monthStart) &&
            bonusInfo.date.isBefore(monthEnd.add(const Duration(days: 1)))) {
          monthlyHours += bonusInfo.workingHours;
          monthlyBonus += bonusInfo.bonus;
        }
      }

      // Label the month according to the pay period's ending month
      final monthLabel = DateFormat('MMMM yyyy').format(monthEnd);
      historicalData.add(MonthlyData(monthLabel, monthlyHours, monthlyBonus));

      // Increment to the next month start from the 19th
      startDate = DateTime(startDate.year, startDate.month + 1, 19);
    }

    return historicalData;
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final isOvertimeProvider = StateProvider<bool>((ref) => false);

final bonusInfoListProvider =
    StateNotifierProvider<BonusInfoNotifier, BonusInfoAndRatio>(
  (ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final userId = authRepo.currentUserId;
    final bonusInfoRepo = ref.read(bonusInfoRepositoryProvider);

    return BonusInfoNotifier(
      bonusInfoRepo,
      userId,
    );
  },
);

final bonusInfoRepositoryProvider = Provider<BonusInfoRepository>((ref) {
  return BonusInfoRepository();
});

final walletSummaryProvider = FutureProvider<WalletSummary>((ref) async {
  final bonusNotifier = ref.read(bonusInfoListProvider.notifier);
  final userState = ref.watch(userNotifierProvider);

  // 3️⃣  Do the maths *inside* the selected range.
  final results = await Future.wait([
    bonusNotifier.getTotalBonus(),
    bonusNotifier.getTotalWorkingHours(),
  ]);
  final totalBonus = results[0];
  final totalHours = results[1];
  final totalSalary = totalBonus + totalHours * (userState.hourlyRate ?? 0);

  return WalletSummary(totalBonus, totalHours, totalSalary);
});

/// Simple model to hold summary data
class WalletSummary {
  const WalletSummary(this.totalBonus, this.totalHours, this.totalSalary);
  final double totalBonus;
  final double totalHours;
  final double totalSalary;
}

extension DateTimeExtensions on DateTime {
  /// Checks if this DateTime is at least (later than or the same as) another DateTime.
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}
