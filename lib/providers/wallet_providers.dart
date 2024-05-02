import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
import 'package:ballistics_wallet_flutter/models/ratio_and_bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BonusInfoNotifier extends StateNotifier<BonusInfoAndRatio> {
  BonusInfoNotifier(this._repository, this.userId)
      : super(BonusInfoAndRatio()) {
    Future.microtask(() async => init());
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

  double getTotalWorkingHours() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    var totalWorkingHours = 0.0;

    // Check the current date to set the date range
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month, 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 19);
      endDate = DateTime(now.year, now.month, 18);
    }

    // Iterate over all bonuses in the current state
    for (final bonusInfo in state.bonusInfo) {
      final date =
          bonusInfo.date; // Assuming `date` is the DateTime field in BonusInfo
      // Check if the date of the bonus is within the range
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        totalWorkingHours += bonusInfo
            .workingHours; // Assuming `workingHours` is a field in BonusInfo
      }
    }

    return totalWorkingHours;
  }

  double getTotalBonus() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;
    var totalBonus = 0.0;

    // Set the date range based on the current date
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month, 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 19);
      endDate = DateTime(now.year, now.month, 18);
    }

    // Iterate over all BonusInfo objects in the current state
    for (final bonusInfo in state.bonusInfo) {
      final date = bonusInfo.date; // Assuming BonusInfo has a 'date' attribute

      // Check if the date of the bonusInfo is within the range
      if ((date.compareTo(startDate) >= 0) && (date.compareTo(endDate) <= 0)) {
        // If the date is within range, sum up the bonus amounts
        totalBonus += bonusInfo
            .bonus; // Replace 'bonusAmount' with the actual property name
      }
    }

    return totalBonus;
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
  (ref) => BonusInfoNotifier(
    BonusInfoRepository(),
    ref.read(authRepositoryProvider).currentUserId,
  ),
);

extension DateTimeExtensions on DateTime {
  /// Checks if this DateTime is at least (later than or the same as) another DateTime.
  bool isAtLeast(DateTime other) {
    return isAfter(other) || isAtSameMomentAs(other);
  }
}
