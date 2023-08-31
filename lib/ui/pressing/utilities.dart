String formatDouble(double value) {
  return value == value.floor() ? value.floor().toString() : value.toStringAsFixed(2);
}