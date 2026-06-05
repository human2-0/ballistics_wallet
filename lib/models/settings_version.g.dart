// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_version.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsVersionAdapter extends TypeAdapter<SettingsVersion> {
  @override
  final int typeId = 100;

  @override
  SettingsVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsVersion(version: fields[0] as int);
  }

  @override
  void write(BinaryWriter writer, SettingsVersion obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
