// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductInfoAdapter extends TypeAdapter<ProductInfo> {
  @override
  final int typeId = 3;

  @override
  ProductInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductInfo(
      productName: fields[0] as String,
      target: fields[1] as int,
      imageName: fields[2] as String,
      product: (fields[3] as List).cast<Pressing>(),
      ayr: fields[4] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.target)
      ..writeByte(2)
      ..write(obj.imageName)
      ..writeByte(3)
      ..write(obj.product)
      ..writeByte(4)
      ..write(obj.ayr);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PressingAdapter extends TypeAdapter<Pressing> {
  @override
  final int typeId = 4;

  @override
  Pressing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pressing(
      fields[1] as String,
      fields[2] as double,
      fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Pressing obj) {
    writer
      ..writeByte(3)
      ..writeByte(1)
      ..write(obj.productColor)
      ..writeByte(2)
      ..write(obj.systemG)
      ..writeByte(3)
      ..write(obj.systemCitric);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PressingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
