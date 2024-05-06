import 'package:hive_flutter/hive_flutter.dart';
part 'settings.g.dart';


@HiveType(typeId: 7) // Specify a unique typeId for ProductInfo
class UserSettings extends HiveObject {
  // Ensure Product model is a Hive object

  UserSettings({
    required this.backup,
    required this.askForBackup,
  });

  @HiveField(0)
  final bool backup;

  @HiveField(1)
  final bool askForBackup;
}
