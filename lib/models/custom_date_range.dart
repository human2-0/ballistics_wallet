// lib/models/custom_date_range.dart
import 'package:hive/hive.dart';

part 'custom_date_range.g.dart';

@HiveType(typeId: 30)
class CustomDateRange extends HiveObject {
  CustomDateRange({
    this.hoursStart,
    this.hoursEnd,
    this.bonusStart,
    this.bonusEnd,
  });
  @HiveField(0)
  DateTime? hoursStart;

  @HiveField(1)
  DateTime? hoursEnd;

  @HiveField(2)
  DateTime? bonusStart;

  @HiveField(3)
  DateTime? bonusEnd;
}
