// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_name.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductNameAdapter extends TypeAdapter<ProductName> {
  @override
  final int typeId = 0;

  @override
  ProductName read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductName(
      name: fields[0] as String,
      target: fields[1] as int,
      imageName: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductName obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.target)
      ..writeByte(2)
      ..write(obj.imageName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductNameAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
