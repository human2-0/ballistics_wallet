String formatDouble(double value) {
  return value == value.floor() ? value.floor().toString() : value.toStringAsFixed(2);
}

String formatProductNameToFileName(String productName) {
  String fileName = productName.toLowerCase();

  // Remove any special characters or numbers
  fileName = fileName.replaceAll(RegExp(r'[^a-z ]'), '');

  // Replace spaces with underscores
  fileName = fileName.replaceAll(' ', '_');

  // Remove any trailing underscores
  fileName = fileName.replaceAll(RegExp(r'_+$'), '');

  return fileName;
}