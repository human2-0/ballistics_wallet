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

  static const Uuid _uuid = Uuid();

  BonusInfo copyWith({
    String? id,
    String? userId,
    double? bonus,
    DateTime? date,
    double? workingHours,
    bool? isOvertime,
    List<Produced>? produced,
  }) {
    return BonusInfo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bonus: bonus ?? this.bonus,
      date: date ?? this.date,
      workingHours: workingHours ?? this.workingHours,
      isOvertime: isOvertime ?? this.isOvertime,
      produced: produced ?? this.produced,
    );
  }

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
  });

  factory Produced.fromMap(Map<String, dynamic> map) {
    return Produced(
      productName: map['productName'] as String,
      amount: map['amount'] as int,
      ratio: (map['ratio'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Produced copyWith({
    String? productName,
    int? amount,
    double? ratio,
  }) {
    return Produced(
      productName: productName ?? this.productName,
      amount: amount ?? this.amount,
      ratio: ratio ?? this.ratio,
    );
  }

  @HiveField(0)
  final String productName;

  @HiveField(1)
  final int amount;

  @HiveField(2)
  final double ratio;
}
