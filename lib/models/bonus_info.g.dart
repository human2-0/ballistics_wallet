// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonus_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BonusInfoAdapter extends TypeAdapter<BonusInfo> {
  @override
  final int typeId = 5;

  @override
  BonusInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BonusInfo(
      userId: fields[1] as String,
      bonus: fields[2] as double,
      date: fields[3] as DateTime,
      workingHours: fields[4] as double,
      isOvertime: fields[5] as bool,
      produced: (fields[6] as List).cast<Produced>(),
      id: fields[0] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BonusInfo obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.bonus)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.workingHours)
      ..writeByte(5)
      ..write(obj.isOvertime)
      ..writeByte(6)
      ..write(obj.produced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BonusInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProducedAdapter extends TypeAdapter<Produced> {
  @override
  final int typeId = 1;

  @override
  Produced read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Produced(
      productName: fields[0] as String,
      amount: fields[1] as int,
      // Use `as double?` to allow null values, and `?? 0.0` to provide a default value if null
      ratio: fields[2] as double? ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, Produced obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.ratio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProducedAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
