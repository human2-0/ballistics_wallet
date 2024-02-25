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
    await box.add(bonusInfo);
  }

  Future<List<BonusInfo>> getAllBonusInfos() async {
    final box = await openBox();
    return box.values.toList();
  }

  Future<void> updateBonusInfo(BonusInfo updatedBonusInfo) async {
    final box = await Hive.openBox<BonusInfo>('bonusInfoBox');
    // Use the unique ID for finding the existing BonusInfo object
    final existingIndex = box.values.toList().indexWhere(
          (bonusInfo) => bonusInfo.id == updatedBonusInfo.id,
    );
    if (existingIndex != -1) {
      await box.putAt(existingIndex, updatedBonusInfo);
    }
  }



  Future<void> deleteBonusInfo(int index) async {
    final box = await openBox();
    await box.deleteAt(index);
  }

  Future<void> deleteProducedFromBonusInfo(int bonusInfoIndex, int producedIndex) async {
    final box = await openBox();
    final bonusInfo = box.getAt(bonusInfoIndex)!;
    final updatedProduced = List<Produced>.from(bonusInfo.produced)..removeAt(producedIndex);
    // Assume BonusInfo has a method `copyWith` for immutability
    final updatedBonusInfo = bonusInfo.copyWith(produced: updatedProduced);
    await box.putAt(bonusInfoIndex, updatedBonusInfo);
  }

  Future<Map<DateTime, List<BonusInfo>>> fetchUserBonuses(String userId) async {
   final bonuses = <DateTime, List<BonusInfo>>{};

    final QuerySnapshot snapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
// Correctly retrieve the Timestamp and convert it to a DateTime
      final timestamp = data['date'] as Timestamp; // Correctly retrieve as Timestamp
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
        'produced': producedList, // Ensure this matches your model's expected structure
      });

      if (!bonuses.containsKey(key)) {
        bonuses[key] = [];
      }
      bonuses[key]!.add(bonusInfo);
    }

    return bonuses;
  }
}
