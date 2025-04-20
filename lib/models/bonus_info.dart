import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'bonus_info.g.dart'; // Hive generates this file

@HiveType(typeId: 5)
class BonusInfo {
  BonusInfo({
    required this.userId,
    required this.bonus,
    required this.date,
    required this.workingHours,
    required this.isOvertime,
    required this.produced,
    String? id,
  }) : id = id ?? BonusInfo._uuid.v4();

  factory BonusInfo.fromMap(Map<String, dynamic> map) {
    const uuid = Uuid();
    return BonusInfo(
      id: uuid.v4(),
      userId: map['userId'] as String,
      bonus: (map['bonus'] as num).toDouble(), // Convert num to double
      date: map['date'] as DateTime,
      workingHours: (map['workingHours'] as num).toDouble(),
      isOvertime: map['isOvertime'] as bool? ?? false,
      produced: (map['produced'] as List<dynamic>?)
              ?.map((e) => Produced.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory BonusInfo.fromFirestore(Map<String, dynamic> firestoreData) {
    return BonusInfo(
      userId: firestoreData['userId'] as String? ?? '', // Provide default if null
      bonus: (firestoreData['bonus'] as num?)?.toDouble() ?? 0.0, // Handle num? and null
      date: (firestoreData['date'] as Timestamp?)?.toDate() ?? DateTime.now(), // Handle Timestamp? and null, default to now
      workingHours: (firestoreData['workingHours'] as num?)?.toDouble() ?? 0.0,
      isOvertime: firestoreData['isOvertime'] as bool? ?? false,
      produced: (firestoreData['produced'] as List<dynamic>? ?? []) // Handle null list
          .map((item) => Produced.fromFirestore(item as Map<String, dynamic>)) // Assuming Produced has fromFirestore too
          .toList(),
    );
  }

  static const Uuid _uuid = Uuid();

  BonusInfo copyWith({
    String? id,
    String? userId,
    double? bonus,
    DateTime? date,
    double? workingHours,
    bool? isOvertime,
    List<Produced>? produced,
  }) => BonusInfo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bonus: bonus ?? this.bonus,
      date: date ?? this.date,
      workingHours: workingHours ?? this.workingHours,
      isOvertime: isOvertime ?? this.isOvertime,
      produced: produced ?? this.produced,
    );

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double bonus;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final double workingHours;

  @HiveField(5)
  final bool isOvertime;

  @HiveField(6)
  final List<Produced> produced;
}

@HiveType(typeId: 1)
class Produced {

  Produced({
    required this.productName,
    required this.amount,
    required this.ratio,
    this.allowance,
  });

  factory Produced.fromMap(Map<String, dynamic> map) => Produced(
    productName: map['productName'] as String,
    amount: map['amount'] as int,
    ratio: (map['ratio'] as num?)?.toDouble() ?? 0.0,
    allowance: (map['allowance'] as num?)?.toDouble(),
  );
  factory Produced.fromFirestore(Map<String, dynamic> firestoreData) {
    return Produced(
      productName: firestoreData['productName'] as String? ?? '',
      amount: firestoreData['amount'] as int? ?? 0,
      ratio: (firestoreData['ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Produced copyWith({
    String? productName,
    int? amount,
    double? ratio,
    double? allowance,
  }) => Produced(
    productName: productName ?? this.productName,
    amount: amount ?? this.amount,
    ratio: ratio ?? this.ratio,
    allowance: allowance ?? this.allowance,
  );

  Map<String, dynamic> toMap() {
    return {
      'productName': productName,
      'amount': amount,
      'ratio': ratio,
      'allowance': allowance, // This will include allowance in the map, even if it is null
    };
  }

  @HiveField(0)
  final String productName;

  @HiveField(1)
  final int amount;

  @HiveField(2)
  final double ratio;

  @HiveField(3)
  final double? allowance;
}
