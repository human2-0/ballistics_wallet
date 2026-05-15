import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

class BonusInfoRepository {
  BonusInfoRepository();
  final String _boxName = 'bonusInfoBox';

  Future<Box<BonusInfo>> openBox() async => Hive.openBox<BonusInfo>(_boxName);

  Future<void> closeBox() async {
    final box = await Hive.openBox<BonusInfo>(_boxName);
    await box.close();
  }

  Future<void> reopenBox() async {
    await closeBox();
    await openBox();
  }

  Future<String> addBonusInfo(BonusInfo bonusInfo) async {
    final box = await openBox();

    // Find an existing BonusInfo entry for the same user and day
    final existingBonus = box.values.firstWhereOrNull(
      (element) =>
          element.userId == bonusInfo.userId &&
          element.date.day == bonusInfo.date.day &&
          element.date.month == bonusInfo.date.month &&
          element.date.year == bonusInfo.date.year,
    );

    if (existingBonus != null) {
      // Iterate over the new produced items to add or update existing ones
      final updatedProducedList = List<Produced>.from(existingBonus.produced);
      for (final newProducedItem in bonusInfo.produced) {
        final index = updatedProducedList.indexWhere(
          (produced) => produced.productName == newProducedItem.productName,
        );
        if (index != -1) {
          // Product exists, update its amount
          updatedProducedList[index] = updatedProducedList[index].copyWith(
            amount: newProducedItem.amount,
            ratio: newProducedItem.ratio,
            allowance: newProducedItem.allowance,
          );
        } else {
          // Product doesn't exist, add new item
          updatedProducedList.add(newProducedItem);
        }
      }
      // Update the existing entry with the modified produced list
      final updatedBonusInfo = existingBonus.copyWith(
        bonus: bonusInfo.bonus,
        produced: updatedProducedList,
      );
      await box.put(existingBonus.id, updatedBonusInfo);

      return 'Product updated successfully.';
    } else {
      // No existing entry, add the new BonusInfo
      await box.put(bonusInfo.id, bonusInfo);
      return '${bonusInfo.produced.first.productName} added to your wallet.';
    }
  }

  Future<List<BonusInfo>> getAllBonusInfos() async {
    final box = await openBox();
    return box.values.toList();
  }

  Future<void> updateBonusInfo(BonusInfo bonusInfo) async {
    final box = await Hive.openBox<BonusInfo>('bonusInfoBox');

    // Find the key of the item that matches the condition
    final keyToUpdate = box.keys.firstWhereOrNull((k) {
      final item = box.get(k);
      return item != null &&
          item.userId == bonusInfo.userId &&
          item.date.day == bonusInfo.date.day &&
          item.date.month == bonusInfo.date.month &&
          item.date.year == bonusInfo.date.year &&
          item.produced.any(
            (produced) =>
                produced.productName == bonusInfo.produced.first.productName,
          );
    });

    // If an existing item is found, update it with the new info
    if (keyToUpdate != null) {
      await box.put(keyToUpdate, bonusInfo);
    }
  }

  Future<void> deleteBonusInfo(BonusInfo info) async {
    final box = await openBox();

    // Find the key of the entry that matches the info you want to delete
    final keyToDelete = box.keys.firstWhereOrNull((k) {
      final currentInfo = box.get(k);
      // Adjust the condition based on attributes that uniquely identify a BonusInfo object
      return currentInfo!.userId == info.userId &&
          currentInfo.date == info.date &&
          currentInfo.produced.any((p) => info.produced.contains(p));
    });

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }

  Future<Map<String, double>> getAllRatiosToday() async {
    final box = await openBox();
    final productInfo = <String, double>{};

    // Assuming BonusInfo objects include a date and a List<Produced>
    final today = DateTime.now();
    for (final bonusInfo in box.values) {
      // Filter bonuses for today and not overtime
      if (bonusInfo.date.day == today.day &&
          bonusInfo.date.month == today.month &&
          bonusInfo.date.year == today.year &&
          !bonusInfo.isOvertime) {
        for (final produced in bonusInfo.produced) {
          // Assuming Produced includes productName and ratio
          productInfo[produced.productName.toLowerCase().trim()] =
              produced.ratio;
        }
      }
    }

    return productInfo;
  }
}
