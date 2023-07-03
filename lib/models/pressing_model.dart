class Pressing {
  final String powdersQr;
  final int quantity;
  final double weight;

  Pressing({
    required this.powdersQr,
    required this.quantity,
    required this.weight,
  });

  factory Pressing.fromJson(Map<String, dynamic> json) {
    return Pressing(
      powdersQr: json['powdersQr'],
      quantity: json['quantity'],
      weight: json['weight'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'powdersQr': powdersQr,
      'quantity': quantity,
      'weight': weight,
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Pressing &&
            runtimeType == other.runtimeType &&
            powdersQr == other.powdersQr &&
            quantity == other.quantity &&
            weight == other.weight;
  }

  @override
  int get hashCode => powdersQr.hashCode ^ quantity.hashCode ^ weight.hashCode;
}
