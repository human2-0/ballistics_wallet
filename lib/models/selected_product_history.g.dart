// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_product_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelectedProductAdapter extends TypeAdapter<SelectedProduct> {
  @override
  final int typeId = 2;

  @override
  SelectedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelectedProduct(
      name: fields[0] as String,
      selectedDate: fields[1] as DateTime,
      target: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, SelectedProduct obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.selectedDate)
      ..writeByte(2)
      ..write(obj.target);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
