// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 7;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      userId: fields[0] as String,
      workingHours: fields[1] as double?,
      realWorkingHours: fields[2] as double?,
      avatarUrl: fields[3] as String?,
      paidBreaks: fields[4] as bool?,
      hourlyRate: fields[5] as double?,
      backup: fields[6] as bool?,
      askForBackup: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.workingHours)
      ..writeByte(2)
      ..write(obj.realWorkingHours)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.paidBreaks)
      ..writeByte(5)
      ..write(obj.hourlyRate)
      ..writeByte(6)
      ..write(obj.backup)
      ..writeByte(7)
      ..write(obj.askForBackup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
