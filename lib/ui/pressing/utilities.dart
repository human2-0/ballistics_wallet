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

String toTitleCase(String text) {
  if (text.isEmpty) return text;

  return text.toLowerCase().split(' ').map((word) {
    final String leftText = word.length > 1 ? word.substring(1) : '';
    return word[0].toUpperCase() + leftText;
  }).join(' ');
}

DateTime nextMonday() {
  DateTime now = DateTime.now();
  int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
  return now.add(Duration(days: daysUntilMonday));
}