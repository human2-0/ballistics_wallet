import 'package:cloud_firestore/cloud_firestore.dart';




// WARNING, THIS REPOSITORY IS DEPRECIATED AS OF PRODUCT INFO REPOSITORY, IT IS KEPT IN CASE I WOULD LIKE TO MIGRATE BACK TO FIRESTORE DATABASE




class PressingRepository {
  PressingRepository();
  final FirebaseFirestore db = FirebaseFirestore.instance;



  Future<void> saveUserBonus(
    String userId,
    String productName,
    double bonus,
    int amount,
    double ratio, {
    double workingHours = 0,
  }) async {
    final CollectionReference userBonusCollection =
        db.collection('userBonuses');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    DocumentReference docRef;
    CollectionReference producedCollection;

    final existingBonus = await userBonusCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .get();

    // Filter out documents where 'isOvertime' is true
    final validBonusDocs = existingBonus.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      // Directly return the condition. If data is null, the condition evaluates to false.
      return data?['isOvertime'] != true;
    }).toList();


    if (validBonusDocs.isNotEmpty) {
      // If a bonus exists for the current day, get its ID and check 'produced' subcollection
      final bonusId = validBonusDocs.first.id;
      docRef = userBonusCollection.doc(bonusId);
    } else {
      // No bonus history for the current user exists for today, create a new document in the 'userBonuses' collection
      docRef = await userBonusCollection.add({
        'userId': userId,
        'bonus': bonus,
        'timestamp': now,
        'date': today,
        'workingHours': workingHours,
      });
    }

    producedCollection = docRef.collection('produced');
    final existingProduced = await producedCollection
        .where('productName', isEqualTo: productName)
        .get();

    if (existingProduced.size > 0) {
      // If documents exist with the same productName, replace the amount and ratio
      for (final doc in existingProduced.docs) {
        final producedId = doc.id;
        await producedCollection.doc(producedId).update({
          'amount': amount,
          'ratio': ratio,
        });
      }
    } else {
      // If no documents with the same productName exist, add a new document
      await producedCollection.add({
        'productName': productName,
        'amount': amount,
        'ratio': ratio,
        'timestamp': now,
      });
    }

    // Update the bonus amount
    await docRef.update({'bonus': bonus});
  }

  Future<void> saveOvertimeUserBonus(
    String userId,
    String productName,
    double bonus,
    int amount,
    double ratio, {
    bool isOvertime = false,
    double workingHours = 0,
  }) async {
    final CollectionReference userBonusCollection =
        db.collection('userBonuses');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final existingBonus = await userBonusCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .where('isOvertime', isEqualTo: true)
        .get();

    if (existingBonus.size > 0) {
      // If the overtime bonus exists, get its ID and check 'produced' subcollection
      final bonusId = existingBonus.docs.first.id;
      final docRef = userBonusCollection.doc(bonusId);
      final CollectionReference producedCollection =
          docRef.collection('produced');
      final existingProduced = await producedCollection
          .where('productName', isEqualTo: productName)
          .get();

      if (existingProduced.size > 0) {
        // If documents exist with the same productName, replace the amount
        for (final doc in existingProduced.docs) {
          final producedId = doc.id;
          await producedCollection.doc(producedId).update({
            'amount': amount,
            'ratio': ratio,
          });
        }
      } else {
        // If no documents with the same productName exist, add a new document
        await producedCollection.add({
          'productName': productName,
          'amount': amount,
          'ratio': ratio,
          'timestamp': now,
        });
      }

      // Update the bonus amount
      await docRef.update({'bonus': bonus});
    } else {
      // No overtime bonus history for the current user exists for today, create a new document in the 'userBonuses' collection
      final docRef = await userBonusCollection.add({
        'userId': userId,
        'bonus': bonus,
        'timestamp': now,
        'date': today,
        'isOvertime': true,
        'workingHours': workingHours,
      });

      // Save product, amount, ratio, and workingHours to the 'produced' subcollection
      final CollectionReference producedCollection =
          docRef.collection('produced');
      await producedCollection.add({
        'productName': productName,
        'amount': amount,
        'ratio': ratio,
        'timestamp': now,
      });
    }
  }

  Future<void> addUserBonus(
    String userId,
    int bonus,
    DateTime selectedDate,
  ) async {
    final userBonusCollection = db.collection('userBonuses');

    // Code to add the new bonus to Firestore
    await userBonusCollection.add({
      'userId': userId,
      'bonus': bonus,
      'date': selectedDate,
    });
  }

  Future<Map<DateTime, List<dynamic>>> fetchUserBonuses(String userId) async {
    final bonuses = <DateTime, List<dynamic>>{};

    final QuerySnapshot snapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in snapshot.docs) {
      // Safely cast the dynamic type to Timestamp and then convert to DateTime
      final timestamp = doc['date'] as Timestamp; // Safe cast to Timestamp
      final date = timestamp.toDate().toLocal();
      final key = DateTime(date.year, date.month, date.day);

      final data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        data['id'] = doc.id; // Include the document ID in the data

        // Fetch 'produced' sub-collection for each userBonus document
        final QuerySnapshot producedSnapshot =
            await doc.reference.collection('produced').get();

        // Create a list to store 'productName' and 'amount' for each product
        final producedList = <Map<String, dynamic>>[];

        for (final producedDoc in producedSnapshot.docs) {
          final producedData = producedDoc.data() as Map<String, dynamic>?;
          if (producedData != null) {
            producedData['id'] =
                producedDoc.id; // Include the document ID in the data
            producedList.add(producedData);
          }
        }

        // Add 'produced' list to the bonus data
        data['produced'] = producedList;

        if (bonuses.containsKey(key)) {
          bonuses[key]!.add(data);
        } else {
          bonuses[key] = [data];
        }
      }
    }

    return bonuses;
  }

  Future<void> editUserBonus(
    String bonusId,
    String producedId,
    double bonus,
    int amount,
  ) async {
    final CollectionReference userBonusCollection =
        db.collection('userBonuses');

    // Edit existing bonus
    try {
      await userBonusCollection
          .doc(bonusId)
          .collection('produced')
          .doc(producedId)
          .update({
        'amount': amount,
        'bonus': bonus,
      });
    } on FormatException {
      rethrow; // rethrow the caught exception while preserving the original stack trace
    }
  }

  Future<void> deleteUserBonus(String bonusId) async {
    final CollectionReference userBonusCollection =
        db.collection('userBonuses');

    // Reference to the 'produced' subcollection
    final CollectionReference producedCollection =
        userBonusCollection.doc(bonusId).collection('produced');

    // Get all documents in the 'produced' subcollection
    final producedSnapshot = await producedCollection.get();

    // Delete all documents in the 'produced' subcollection
    for (final DocumentSnapshot producedDoc in producedSnapshot.docs) {
      await producedDoc.reference.delete();
    }

    // Delete the bonus
    await userBonusCollection.doc(bonusId).delete();
  }

  Future<void> deleteIndividualBonus(
    String userId,
    String bonusId,
    String itemId,
  ) async {
    final CollectionReference userBonusCollection =
        db.collection('userBonuses');
    await userBonusCollection
        .doc(bonusId)
        .collection('produced')
        .doc(itemId)
        .delete();
  }

  Future<Map<String, dynamic>> getUserProductInfo(String userId) async {
    final userInfo = <String, dynamic>{};

    // Initialize Firestore instance
    final db = FirebaseFirestore.instance;

    // Get current date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Fetch user's bonuses for today
    final QuerySnapshot userBonusesSnapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .get();

    for (final DocumentSnapshot bonusDoc in userBonusesSnapshot.docs) {
      // Safely cast isOvertime to bool, defaulting to false if not present or not a bool
      final data = bonusDoc.data() as Map<String, dynamic>?;
      final isOvertime = data?['isOvertime'] == true;

      if (!isOvertime) {
        final QuerySnapshot producedSnapshot =
        await bonusDoc.reference.collection('produced').get();
        for (final DocumentSnapshot producedDoc in producedSnapshot.docs) {
          final data = producedDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final productName = data['productName'] as String?;
            final ratio = data['ratio'] as num?; // Cast to num to handle both int and double

            // Process productName and ratio
            if (productName != null && ratio != null) {
              userInfo[productName.toLowerCase().trim()] = ratio.toDouble(); // Ensure ratio is treated as double
            }
          }
        }
      }
    }

    return userInfo;
  }
}
