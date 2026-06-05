import 'package:hive/hive.dart';

part 'settings_version.g.dart';

@HiveType(typeId: 100)
class SettingsVersion {
  SettingsVersion({required this.version});
  @HiveField(0)
  final int version;
}
