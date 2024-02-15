// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SelectedProductAdapter extends TypeAdapter<SelectedProduct> {
  @override
  final int typeId = 6;

  @override
  SelectedProduct read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SelectedProduct(
      date: fields[0] as DateTime,
      productInfo: fields[1] as ProductInfo,
    );
  }

  @override
  void write(BinaryWriter writer, SelectedProduct obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.productInfo);
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
