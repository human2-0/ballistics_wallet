import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 7)
class UserSettings extends HiveObject {
  UserSettings({
    required this.userId,
    double? workingHours,
    double? realWorkingHours,
    String? avatarUrl,
    bool? paidBreaks,
    double? hourlyRate,
    bool? backup,
    bool? askForBackup,
  }) : workingHours =
           workingHours ??
           _calculateEffectiveWorkingHours(
             workingHours ?? 8.0,
           ), // Default to 8.0 hours
       realWorkingHours = realWorkingHours ?? 8.0,
       avatarUrl = avatarUrl ?? 'assets/default_avatar.webp',
       paidBreaks = paidBreaks ?? false,
       hourlyRate = hourlyRate ?? 13.4, // Default to $20/hour
       backup = backup ?? true,
       askForBackup = askForBackup ?? true;

  @HiveField(0)
  final String userId;

  @HiveField(1)
  late final double workingHours;

  @HiveField(2)
  late final double realWorkingHours;

  @HiveField(3)
  final String avatarUrl;

  @HiveField(4)
  late final bool paidBreaks;

  @HiveField(5)
  late final double hourlyRate;

  @HiveField(6)
  final bool backup;

  @HiveField(7)
  final bool askForBackup;

  static double _calculateEffectiveWorkingHours(double workingHours) {
    if (workingHours == 8.0) {
      return workingHours - 1.0;
    } else if (workingHours == 4.0) {
      return workingHours - 0.25;
    } else if (workingHours == 6.0) {
      return workingHours - 0.5;
    } else {
      return workingHours;
    }
  }

  UserSettings copyWith({
    String? userId,
    double? workingHours,
    double? realWorkingHours,
    String? avatarUrl,
    bool? paidBreaks,
    double? hourlyRate,
    bool? backup,
    bool? askForBackup,
  }) => UserSettings(
    userId: userId ?? this.userId,
    workingHours: workingHours ?? this.workingHours,
    realWorkingHours: realWorkingHours ?? this.realWorkingHours,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    paidBreaks: paidBreaks ?? this.paidBreaks,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    backup: backup ?? this.backup,
    askForBackup: askForBackup ?? this.askForBackup,
  );
}
