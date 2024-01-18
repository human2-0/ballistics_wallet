import 'package:ballistics_wallet_flutter/repository/pressing_db_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class UserBonusNotifier extends StateNotifier<Map<DateTime, List<dynamic>>> {
  UserBonusNotifier(this._repository) : super({});

  final PressingRepository _repository;

  Future<void> saveUserBonusCalendar(String userId, String productName,
      double bonus, int amount, DateTime selectedEventDate, double workingHours,
      {bool isOvertime = false,}) async {
    try {
      final CollectionReference userBonusCollection =
      _repository.db.collection('userBonuses');
      final date = DateTime(selectedEventDate.year, selectedEventDate.month,
          selectedEventDate.day,);
      final nextDate = DateTime(selectedEventDate.year,
          selectedEventDate.month, selectedEventDate.day + 1,);

      final existingBonus = await userBonusCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: date)
          .where('date', isLessThan: nextDate)
          .where('isOvertime', isEqualTo: isOvertime)
          .get();

      DocumentReference docRef;
      CollectionReference producedCollection;

      if (existingBonus.size > 0) {
        // If the bonus exists for the selected date with the same 'isOvertime' status, get its ID
        final bonusId = existingBonus.docs.first.id;
        docRef = userBonusCollection.doc(bonusId);
      } else {
        // Create new bonus document for the selected date
        docRef = await userBonusCollection.add({
          'userId': userId,
          'bonus': bonus,
          'date': date,
          'workingHours': workingHours,
          'isOvertime': isOvertime,
        });
      }

      producedCollection = docRef.collection('produced');

      final existingProduced = await producedCollection
          .where('productName', isEqualTo: productName)
          .get();

      if (existingProduced.size > 0) {
        // If documents exist with the same productName, update the amount
        for (final doc in existingProduced.docs) {
          final producedId = doc.id;
          await _repository.db.runTransaction((transaction) async {
            transaction
                .update(producedCollection.doc(producedId), {'amount': amount});
          });
        }
      } else {
        // Add new product and amount to the 'produced' subcollection
        await producedCollection.add({
          'productName': productName,
          'amount': amount,
        });
      }
    } on FormatException catch (e) {debugPrint(e.message);}
  }


  Future<void> fetchUserBonuses(String userId) async {
    final bonuses =
    await _repository.fetchUserBonuses(userId);
    state = bonuses;
  }

  Future<void> editBonus(
      String userId, String bonusId, double newBonusAmount,) async {
    // Update the bonus in the database
    await _repository.db
        .collection('userBonuses')
        .doc(bonusId)
        .update({'bonus': newBonusAmount});

    // Update the bonus in the state
    for (final date in state.keys) {
      // Ensure that each value in the map is a List<Map<String, dynamic>>
      if (state[date] is List<Map<String, dynamic>>) {
        // Cast the value to the correct type
        final bonuses = state[date]! as List<Map<String, dynamic>>;

        // Check if any bonus in the list matches the condition
        if (bonuses.any((bonus) => bonus['id'] == bonusId)) {
          // Map each bonus, updating the one that matches the condition
          state[date] = bonuses.map((bonus) {
            if (bonus['id'] == bonusId) {
              return {
                ...bonus,
                'bonus': newBonusAmount,
              };
            } else {
              return bonus;
            }
          }).toList();
        }
      }
    }
  }

  Future<void> deleteUserBonus(String bonusId, String userId) async {
    await _repository.deleteUserBonus(bonusId);
    final updatedBonuses =
    await _repository.fetchUserBonuses(userId);
    state = updatedBonuses;
    // Update the state by removing the deleted bonus
    state.removeWhere((date, bonuses) {
      bonuses.removeWhere((bonus) => bonus['id'] == bonusId);
      return bonuses.isEmpty;
    });
    // Notify listeners of the state change
  }

  Future<void> deleteIndividualBonus(
      String userId, String bonusId, String itemId,) async {
    await _repository.deleteIndividualBonus(userId, bonusId, itemId);
    final updatedBonuses =
    await _repository.fetchUserBonuses(userId);
    state = updatedBonuses;
  }

  void setUserBonuses(Map<DateTime, List<dynamic>> bonuses) {
    state = bonuses;
  }

}

class BonusTableSelector extends StateNotifier<bool> {
  BonusTableSelector() : super(false);

  void toggle() {
    state = !state;
  }
}

class TextFieldStateNotifier extends StateNotifier<TextEditingController> {
  TextFieldStateNotifier(String initialValue)
      : super(TextEditingController(text: initialValue));

  void setText(String value) {
    state.text = value;
  }
}
