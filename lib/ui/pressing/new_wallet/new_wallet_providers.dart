import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/bonus_info_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final bonusInfoListProvider =
    StateNotifierProvider<BonusInfoNotifier, List<BonusInfo>>(
  (ref) => BonusInfoNotifier(
    BonusInfoRepository(),
    ref.read(authRepositoryProvider).currentUserId,
  ),
);

class BonusInfoNotifier extends StateNotifier<List<BonusInfo>> {
  BonusInfoNotifier(this._repository, this.userId) : super([]);
  final BonusInfoRepository _repository;
  final String userId;

  Future<void> loadBonusInfos() async {
    final box = await _repository.openBox(); // Ensure this method is accessible
    await box.clear();
    if (box.isEmpty) {
      final bonuses = await _repository.fetchUserBonuses(userId);
      // Flatten the Map<DateTime, List<BonusInfo>> to a single List<BonusInfo>
      state = bonuses.values.expand((list) => list).toList();
    } else {
      state = box.values.toList();
    }
  }

  Future<void> addBonusInfo(BonusInfo bonusInfo) async {
    await _repository.addBonusInfo(bonusInfo);
    await loadBonusInfos(); // Reload the list after adding
  }

  Future<void> updateBonusInfo(int index, BonusInfo bonusInfo) async {
    await _repository.updateBonusInfo(bonusInfo);
    await loadBonusInfos(); // Reload the list after updating
  }

  Future<void> deleteBonusInfo(int index) async {
    await _repository.deleteBonusInfo(index);
    await loadBonusInfos(); // Reload the list after deleting
  }

  Future<void> deleteProducedFromBonusInfo(
    int bonusInfoIndex,
    int producedIndex,
  ) async {
    await _repository.deleteProducedFromBonusInfo(
      bonusInfoIndex,
      producedIndex,
    );
    await loadBonusInfos(); // Reload the list after modification
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
    for (final bonusInfo in state) {
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
    for (final bonusInfo in state) {
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
}
