import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class BonusInfoRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String _boxName = 'bonusInfoBox';

  Future<Box<BonusInfo>> openBox() async {
    return Hive.openBox<BonusInfo>(_boxName);
  }

  Future<void> addBonusInfo(BonusInfo bonusInfo) async {
    final box = await openBox();
    await box.put(bonusInfo.id,bonusInfo);
  }

  Future<List<BonusInfo>> getAllBonusInfos() async {
    final box = await openBox();
    return box.values.toList();
  }

  Future<void> updateBonusInfo(BonusInfo updatedBonusInfo) async {
    final box = await openBox();

    // Search for the key that matches the updatedBonusInfo.id
    dynamic targetKey;
    box.toMap().forEach((key, value) {
      if (key == updatedBonusInfo.id) {
        targetKey = key;
      }
    });

    // If a matching key is found, update the BonusInfo at that key
    if (targetKey != null) {
      await box.put(targetKey, updatedBonusInfo);
    } else {
    }
  }


  Future<void> deleteBonusInfo(BonusInfo info) async {
    final box = await openBox();
    await box.delete(info.id);
  }

  Future<void> deleteProducedFromBonusInfo(
      int bonusInfoIndex, int producedIndex,) async {
    final box = await openBox();
    final bonusInfo = box.getAt(bonusInfoIndex)!;
    final updatedProduced = List<Produced>.from(bonusInfo.produced)
      ..removeAt(producedIndex);
    // Assume BonusInfo has a method `copyWith` for immutability
    final updatedBonusInfo =
        bonusInfo.copyWith(id: bonusInfo.id, produced: updatedProduced);
    await box.putAt(bonusInfoIndex, updatedBonusInfo);
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
}
