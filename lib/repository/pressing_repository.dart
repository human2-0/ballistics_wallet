import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const Map<int, double> bonusPercentageMap = {
  1: 102.00,
  2: 104.10,
  3: 106.10,
  4: 108.20,
  5: 110.20,
  6: 112.20,
  7: 114.29,
  8: 118.37,
  9: 122.45,
  10: 126.53,
  11: 130.61,
  12: 134.69,
  13: 138.78,
  14: 142.86,
  15: 146.94,
  16: 151.02,
  17: 155.10,
  18: 159.18,
  19: 163.27,
  20: 167.35,
  21: 171.43, //Add more values as per your requirements
};

class PressingRepository {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  PressingRepository();

  Future<void> addProduct(String productName, int target) async {
    // Convert the product name to title case
    String formattedProductName = toTitleCase(productName);

    // Check if a product with the same name already exists
    var productDoc =
        await db.collection("Products").doc(formattedProductName).get();

    if (productDoc.exists) {
      // If the product already exists, throw an error or return
      throw Exception('A product with the same name already exists');
    } else {
      // If the product does not exist, add it to the database
      await db.collection("Products").doc(formattedProductName).set({
        'name': formattedProductName,
        'target': target,
      });
    }
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return text;

    return text.toLowerCase().split(' ').map((word) {
      final String leftText = word.length > 1 ? word.substring(1) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }

  Future<List<String>> readProductNames() async {
    QuerySnapshot querySnapshot = await db.collection("Products").get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<Map<String, dynamic>>> readProductsPressing() async {
    Box box = Hive.box('Products');
    print('Read Products: ${box.toMap()}');
    List<Map<String, dynamic>> products = box.keys.map((key) {
      final product = {
        'name': key,
        'target': box.get(key) as int,
      };
      return product;
    }).toList();

    return products;
  }

  Future<Map<String, dynamic>> getBonuses() async {
    Map<String, int> swappedMap =
        bonusPercentageMap.map((key, value) => MapEntry(value.toString(), key));

    return swappedMap;
  }

  Future<void> saveUserBonus(
      String userId, String productName, double bonus, int amount, double ratio,
      {double workingHours = 0}) async {
    CollectionReference userBonusCollection = db.collection('userBonuses');

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    DocumentReference docRef;
    CollectionReference producedCollection;

    QuerySnapshot existingBonus = await userBonusCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .get();

    // Filter out documents where 'isOvertime' is true
    final validBonusDocs = existingBonus.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data != null ? data['isOvertime'] != true : true;
    }).toList();

    if (validBonusDocs.isNotEmpty) {
      // If a bonus exists for the current day, get its ID and check 'produced' subcollection
      String bonusId = validBonusDocs.first.id;
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
    QuerySnapshot existingProduced = await producedCollection
        .where('productName', isEqualTo: productName)
        .get();

    if (existingProduced.size > 0) {
      // If documents exist with the same productName, replace the amount and ratio
      for (QueryDocumentSnapshot doc in existingProduced.docs) {
        String producedId = doc.id;
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
      String userId, String productName, double bonus, int amount, double ratio,
      {bool isOvertime = false, double workingHours = 0}) async {
    CollectionReference userBonusCollection = db.collection('userBonuses');

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    QuerySnapshot existingBonus = await userBonusCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .where('isOvertime', isEqualTo: true)
        .get();

    if (existingBonus.size > 0) {
      // If the overtime bonus exists, get its ID and check 'produced' subcollection
      String bonusId = existingBonus.docs.first.id;
      DocumentReference docRef = userBonusCollection.doc(bonusId);
      CollectionReference producedCollection = docRef.collection('produced');
      QuerySnapshot existingProduced = await producedCollection
          .where('productName', isEqualTo: productName)
          .get();

      if (existingProduced.size > 0) {
        // If documents exist with the same productName, replace the amount
        for (QueryDocumentSnapshot doc in existingProduced.docs) {
          String producedId = doc.id;
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
      DocumentReference docRef = await userBonusCollection.add({
        'userId': userId,
        'bonus': bonus,
        'timestamp': now,
        'date': today,
        'isOvertime': true,
        'workingHours': workingHours,
      });

      // Save product, amount, ratio, and workingHours to the 'produced' subcollection
      CollectionReference producedCollection = docRef.collection('produced');
      await producedCollection.add({
        'productName': productName,
        'amount': amount,
        'ratio': ratio,
        'timestamp': now,
      });
    }
  }

  Future<void> addUserBonus(
      String userId, int bonus, DateTime selectedDate) async {
    final userBonusCollection = db.collection('userBonuses');

    // Code to add the new bonus to Firestore
    await userBonusCollection.add({
      'userId': userId,
      'bonus': bonus,
      'date': selectedDate,
    });
  }

  Future<Map<DateTime, List<dynamic>>> fetchUserBonuses(String userId) async {
    Map<DateTime, List<dynamic>> bonuses = {};

    QuerySnapshot snapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      DateTime date = doc['date'].toDate().toLocal();
      DateTime key = DateTime(date.year, date.month, date.day);

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        data['id'] = doc.id; // Include the document ID in the data

        // Fetch 'produced' sub-collection for each userBonus document
        QuerySnapshot producedSnapshot =
            await doc.reference.collection('produced').get();

        // Create a list to store 'productName' and 'amount' for each product
        List<Map<String, dynamic>> producedList = [];

        for (var producedDoc in producedSnapshot.docs) {
          Map<String, dynamic>? producedData =
              producedDoc.data() as Map<String, dynamic>?;
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
      String bonusId, String producedId, double bonus, int amount) async {
    CollectionReference userBonusCollection = db.collection('userBonuses');

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
    } catch (e) {
      rethrow; // rethrow the caught exception while preserving the original stack trace
    }
  }

  Future<void> deleteUserBonus(String bonusId) async {
    CollectionReference userBonusCollection = db.collection('userBonuses');

    // Reference to the 'produced' subcollection
    CollectionReference producedCollection =
        userBonusCollection.doc(bonusId).collection('produced');

    // Get all documents in the 'produced' subcollection
    QuerySnapshot producedSnapshot = await producedCollection.get();

    // Delete all documents in the 'produced' subcollection
    for (DocumentSnapshot producedDoc in producedSnapshot.docs) {
      await producedDoc.reference.delete();
    }

    // Delete the bonus
    await userBonusCollection.doc(bonusId).delete();
  }

  Future<void> deleteIndividualBonus(
      String userId, String bonusId, String itemId) async {
    CollectionReference userBonusCollection = db.collection('userBonuses');
    await userBonusCollection
        .doc(bonusId)
        .collection('produced')
        .doc(itemId)
        .delete();
  }

  Future<Map<String, dynamic>> getUserProductInfo(String userId) async {
    Map<String, dynamic> userInfo = {};

    // Get current date
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Fetch user's bonuses for today
    QuerySnapshot userBonusesSnapshot = await db
        .collection('userBonuses')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: today)
        .where('date', isLessThan: tomorrow)
        .get();

    // For each bonus, iterate through the 'produced' sub-collection
    for (var bonusDoc in userBonusesSnapshot.docs) {
      // Check if the current bonus document isOvertime
      bool isOvertime =
          (bonusDoc.data() as Map<String, dynamic>)['isOvertime'] ?? false;

      // Only process the 'produced' sub-collection if isOvertime is false
      if (!isOvertime) {
        QuerySnapshot producedSnapshot =
            await bonusDoc.reference.collection('produced').get();
        for (var producedDoc in producedSnapshot.docs) {
          var data = producedDoc.data() as Map<String, dynamic>?;
          String? productName = data?['productName'].toLowerCase().trim();
          double? ratio = data?['ratio'];

          // Store ratio
          if (productName != null && ratio != null) {
            userInfo[productName] = ratio;
          }
        }
      }
    }

    return userInfo;
  }
}

final productNamesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(pressingRepositoryProvider);
  final productNames = await repository.readProductNames();
  return productNames;
});

class TargetRatioNotifier extends StateNotifier<double> {
  final PressingRepository _repository;
  final String _userId;
  Map<String, double> _productRatios = {};

  TargetRatioNotifier(this._repository, this._userId) : super(0.0) {
    init();
  }

  Future<void> init() async {
    // Fetch necessary data from database
    final Map<String, dynamic> data =
        await _repository.getUserProductInfo(_userId);
    if (data.isEmpty) {
      _productRatios = {};
    }

    // Ensure that the notifier has not been disposed of before continuing.
    // StateNotifier.mounted returns a bool that is true if the notifier has not been disposed of.
    if (!mounted) return;

    // Store the data in the _productRatios map
    _productRatios = data.map((key, value) => MapEntry(key, value as double));

    // Calculate the total ratio and update the state
    state = _productRatios.values.fold(0, (a, b) => a + b);
  }

  void updateRatio(String productName, int productTarget, int userNumber,
      double workingHours, double allowanceProvided) {
    productName = productName.toLowerCase();
    int productTargetAdjusted;

    // If workingHours are equal to 8, adjust productTarget with respect to workingHours and allowance
    if (workingHours == 8) {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / 7.00)).ceil();
    }
    // If workingHours are less than 8, adjust productTarget only with respect to allowance
    else {
      productTargetAdjusted =
          (productTarget * ((workingHours - allowanceProvided) / workingHours))
              .ceil();
    }

    // Handle zero cases
    if (userNumber == 0 || productTargetAdjusted == 0) {
      // If this product is already in the map, remove it
      _productRatios.remove(productName);
    } else {
      // Calculate the ratio
      double newRatio = userNumber / productTargetAdjusted.toDouble();

      // Update the map
      _productRatios[productName] = newRatio;
      print('updated list ${_productRatios}');
    }

    // Recalculate the total ratio and update the state
    state = _productRatios.values.fold(0.0, (a, b) => a + b);
  }

  double getProductRatio(String productName) {
    productName = productName.toLowerCase().trim();
    print('here is product ratio list ${_productRatios}');
    print(productName);
    print('text above is provided product name');
    // Normalize productName to lower case and trim spaces

    return _productRatios[productName] ?? 0;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

final targetRatioProvider = StateNotifierProvider.autoDispose
    .family<TargetRatioNotifier, double, String>((ref, userId) {
  return TargetRatioNotifier(ref.watch(pressingRepositoryProvider), userId);
});

class NumberNotifier extends StateNotifier<int> {
  NumberNotifier() : super(0);

  void updateNumber(int newNumber) {
    state = newNumber;
  }
}

final numberProvider = StateNotifierProvider<NumberNotifier, int>((ref) {
  return NumberNotifier();
});

class TargetNotifier extends StateNotifier<int> {
  TargetNotifier() : super(0);

  void updateTarget(int newTarget) {
    state = newTarget;
  }
}

final targetProvider =
    StateNotifierProvider<TargetNotifier, int>((ref) => TargetNotifier());

class UserBonusesNotifier extends StateNotifier<Map<DateTime, List<dynamic>>> {
  UserBonusesNotifier() : super({});

  void setUserBonuses(Map<DateTime, List<dynamic>> userBonuses) {
    state = userBonuses;
  }

  int calculateMonthlyBonus() {
    DateTime now = DateTime.now();

    // if today is before the 20th, count from the 20th of the previous month
    // otherwise, count from the 20th of this month
    int startMonth = now.day < 20 ? now.month - 1 : now.month;
    int startYear =
        now.month == 1 && startMonth == 12 ? now.year - 1 : now.year;

    DateTime start = DateTime(startYear, startMonth, 19);
    DateTime end = DateTime(startYear, startMonth + 1, 18);

    int totalBonus = 0;

    for (var entry in state.entries) {
      DateTime date = entry.key;
      List<dynamic> bonuses = entry.value;

      if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
          (date.isBefore(end) || date.isAtSameMomentAs(end))) {
        for (var bonus in bonuses) {
          var bonusValue = bonus['bonus'];
          if (bonusValue is num) {
            totalBonus += bonusValue.round();
          }
        }
      }
    }

    return totalBonus;
  }
}

final userBonusesProvider =
    StateNotifierProvider<UserBonusesNotifier, Map<DateTime, List<dynamic>>>(
        (ref) {
  return UserBonusesNotifier();
});

final pressingRepositoryProvider = Provider<PressingRepository>((ref) {
  return PressingRepository();
});

final productUpdateProvider =
    StateNotifierProvider<ProductUpdateNotifier, bool>((ref) {
  return ProductUpdateNotifier();
});

class ProductUpdateNotifier extends StateNotifier<bool> {
  ProductUpdateNotifier() : super(false);

  void update() {
    state = !state;
  }
}

final productsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, bool>((ref, updated) async {
  final repository = ref.read(pressingRepositoryProvider);
  final products = await repository.readProductsPressing();
  return products;
});

final bonusValueProvider = Provider.family<double, double>((ref, targetRatio) {
  targetRatio *= 100; // Convert targetRatio to percentage

  print("Target ratio: $targetRatio"); // Check the input

  // Sort the keys in ascending order
  final sortedKeys = bonusPercentageMap.keys.toList()
    ..sort((a, b) => b.compareTo(a)); // We sort in descending order

  double bonus = 0.0;
  for (final key in sortedKeys) {
    print(
        "Checking key: $key, percentage: ${bonusPercentageMap[key]}"); // Check the logic

    if (targetRatio >= (bonusPercentageMap[key] ?? 0)) {
      bonus = key.toDouble();
      break;
    }
  }

  print("Bonus: $bonus"); // Check the output

  return bonus;
});

class UserBonusNotifier extends StateNotifier<Map<DateTime, List<dynamic>>> {
  UserBonusNotifier(this._repository) : super({});

  final PressingRepository _repository;

  Future<void> saveUserBonusCalendar(String userId, String productName,
      double bonus, int amount, DateTime selectedEventDate, double workingHours,
      {bool isOvertime = false}) async {
    try {
      CollectionReference userBonusCollection =
          _repository.db.collection('userBonuses');
      DateTime date = DateTime(selectedEventDate.year, selectedEventDate.month,
          selectedEventDate.day);
      DateTime nextDate = DateTime(selectedEventDate.year,
          selectedEventDate.month, selectedEventDate.day + 1);

      QuerySnapshot existingBonus = await userBonusCollection
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: date)
          .where('date', isLessThan: nextDate)
          .where('isOvertime', isEqualTo: isOvertime)
          .get();

      DocumentReference docRef;
      CollectionReference producedCollection;

      if (existingBonus.size > 0) {
        // If the bonus exists for the selected date with the same 'isOvertime' status, get its ID
        String bonusId = existingBonus.docs.first.id;
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

      QuerySnapshot existingProduced = await producedCollection
          .where('productName', isEqualTo: productName)
          .get();

      if (existingProduced.size > 0) {
        // If documents exist with the same productName, update the amount
        for (QueryDocumentSnapshot doc in existingProduced.docs) {
          String producedId = doc.id;
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
    } catch (e) {}
  }

  Future<void> saveUserBonus(
      String userId, int bonus, DateTime selectedDate) async {
    // Code to save the new bonus to Firestore using the repository
    await _repository.addUserBonus(userId, bonus, selectedDate);

    // Add the new bonus to the correct date in the state map
  }

  Future<void> saveUserProduct(
      String userId, int bonus, DateTime selectedDate) async {
    // Code to save the new bonus to Firestore using the repository
    await _repository.addUserBonus(userId, bonus, selectedDate);

    // Add the new bonus to the correct date in the state map
  }

  Future<void> fetchUserBonuses(String userId) async {
    Map<DateTime, List<dynamic>> bonuses =
        await _repository.fetchUserBonuses(userId);
    setUserBonuses(bonuses);
  }

  Future<void> editBonus(
      String userId, String bonusId, double newBonusAmount) async {
    // Update the bonus in the database
    await _repository.db
        .collection('userBonuses')
        .doc(bonusId)
        .update({'bonus': newBonusAmount});

    // Update the bonus in the state
    for (var date in state.keys) {
      if (state[date] != null) {
        if (state[date]!.any((bonus) => bonus['id'] == bonusId)) {
          state[date] = state[date]!.map((bonus) {
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
    Map<DateTime, List<dynamic>> updatedBonuses =
        await _repository.fetchUserBonuses(userId);
    setUserBonuses(updatedBonuses);
    // Update the state by removing the deleted bonus
    state.removeWhere((date, bonuses) {
      bonuses.removeWhere((bonus) => bonus['id'] == bonusId);
      return bonuses.isEmpty;
    });
    // Notify listeners of the state change
  }

  Future<void> deleteIndividualBonus(
      String userId, String bonusId, String itemId) async {
    await _repository.deleteIndividualBonus(userId, bonusId, itemId);
    Map<DateTime, List<dynamic>> updatedBonuses =
        await _repository.fetchUserBonuses(userId);
    setUserBonuses(updatedBonuses);
  }

  void setUserBonuses(Map<DateTime, List<dynamic>> bonuses) {
    state = bonuses;
  }

  int calculateMonthlyBonus() {
    int totalBonus = 0;
    for (var bonuses in state.values) {
      for (var bonus in bonuses) {
        totalBonus = (totalBonus + bonus['bonus']).toInt();
      }
    }
    return totalBonus;
  }
}

final userBonusNotifierProvider =
    StateNotifierProvider<UserBonusNotifier, Map<DateTime, List<dynamic>>>(
        (ref) {
  final repository = ref.watch(pressingRepositoryProvider);
  return UserBonusNotifier(repository);
});

class SelectedEventsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  SelectedEventsNotifier() : super([]);

  void setSelectedEvents(List<Map<String, dynamic>> events) {
    state = events;
  }

  void addBonus(Map<String, dynamic> newBonus) {
    state = [...state, newBonus];
  }

  void removeBonus(int parentIndex, int childIndex) {
    state[parentIndex]['produced'].removeAt(childIndex);
    state = List.from(state);
  }

  void editBonusAmount(double newBonus, int parentIndex) {
    state[parentIndex]['bonus'] = newBonus;
    state = List.from(state);
  }
}

final selectedEventsProvider =
    StateNotifierProvider<SelectedEventsNotifier, List<Map<String, dynamic>>>(
        (ref) => SelectedEventsNotifier());

final allowanceProvider = StateProvider<double>((ref) => 0.0);

final overtimeRatioProvider = StateProvider<double>((ref) => 0.0);
final overtimeWorkingHoursState = StateProvider<int?>((ref) => 0);

final monthlyWorkingHoursProvider = StateProvider<double>((ref) => 0.0);

final searchTermProvider = StateProvider<String>((ref) => '');

final selectedProductProvider = StateProvider<StateController<String>>(
    (ref) => StateController<String>(""));

final productsMade = StateProvider<int>((ref) => 0);
