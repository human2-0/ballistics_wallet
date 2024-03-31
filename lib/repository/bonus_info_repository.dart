import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';

class BonusInfoRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String _boxName = 'bonusInfoBox';

  Future<Box<BonusInfo>> openBox() async {
    return Hive.openBox<BonusInfo>(_boxName);
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
        final index = updatedProducedList.indexWhere((produced) => produced.productName == newProducedItem.productName);
        if (index != -1) {
          // Product exists, update its amount
          updatedProducedList[index] = updatedProducedList[index].copyWith(amount: newProducedItem.amount);
        } else {
          // Product doesn't exist, add new item
          updatedProducedList.add(newProducedItem);
        }
      }
      // Update the existing entry with the modified produced list
      final updatedBonusInfo = existingBonus.copyWith(produced: updatedProducedList);
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
    final keyToUpdate = box.keys.firstWhereOrNull(
          (k) {
        final item = box.get(k);
        return item != null &&
            item.userId == bonusInfo.userId &&
            item.date.day == bonusInfo.date.day &&
            item.date.month == bonusInfo.date.month &&
            item.date.year == bonusInfo.date.year &&
            item.produced.any((produced) => produced.productName == bonusInfo.produced.first.productName);
      },
    );

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


  Future<Map<String, List<BonusInfo>>> fetchUserBonuses(String userId) async {
    final bonuses = <String, List<BonusInfo>>{};

    final QuerySnapshot snapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .get();

    final box = await openBox();
    for (final doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
// Correctly retrieve the Timestamp and convert it to a DateTime
      final timestamp =
          data['date'] as Timestamp; // Correctly retrieve as Timestamp
      final date = timestamp.toDate(); // Convert to DateTime
      final key = DateTime(date.year, date.month, date.day);

      // Fetch 'produced' sub-collection for each 'userBonuses' document
      final producedList = <Map<String, dynamic>>[];
      final producedSnapshot = await doc.reference.collection('produced').get();
      for (final producedDoc in producedSnapshot.docs) {
        final producedData = producedDoc.data();
        producedList.add({
          'productName': producedData['productName'],
          'amount': producedData['amount'],
        });
      }

      // Convert to BonusInfo object, adjusting fromMap method or using an alternative constructor if necessary
      final bonusInfo = BonusInfo.fromMap({
        'userId': data['userId'],
        'bonus': data['bonus'],
        'date': key, // Use 'key' as the date
        'workingHours': data['workingHours'],
        'isOvertime': data['isOvertime'],
        'produced':
            producedList, // Ensure this matches your model's expected structure
      });

      await box.put(bonusInfo.id, bonusInfo);

      if (!bonuses.containsKey(bonusInfo.id)) {
        bonuses[bonusInfo.id] = [];
      }

      bonuses[bonusInfo.id]!.add(bonusInfo);
    }

    return bonuses;
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
          productInfo[produced.productName.toLowerCase().trim()] = produced.ratio;
        }
      }
    }

    return productInfo;
  }
}
