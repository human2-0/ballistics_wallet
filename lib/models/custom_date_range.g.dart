// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_date_range.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomDateRangeAdapter extends TypeAdapter<CustomDateRange> {
  @override
  final int typeId = 30;

  @override
  CustomDateRange read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomDateRange(
      hoursStart: fields[0] as DateTime?,
      hoursEnd: fields[1] as DateTime?,
      bonusStart: fields[2] as DateTime?,
      bonusEnd: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomDateRange obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.hoursStart)
      ..writeByte(1)
      ..write(obj.hoursEnd)
      ..writeByte(2)
      ..write(obj.bonusStart)
      ..writeByte(3)
      ..write(obj.bonusEnd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomDateRangeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
