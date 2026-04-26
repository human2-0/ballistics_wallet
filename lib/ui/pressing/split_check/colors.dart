import 'package:flutter/material.dart';

const splitCheckColorOptions = <String>[
  'red',
  'green',
  'blue',
  'yellow',
  'orange',
  'purple',
  'lilac',
  'pink',
  'white',
];

const splitCheckPaletteColors = <Color>[
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
  Colors.black,
  Colors.white,
];

String colorToHex(Color color) {
  final value = color.value.toRadixString(16).padLeft(8, '0');
  return '#${value.substring(2).toUpperCase()}';
}

Color? parseColorString(String colorName) {
  final trimmed = colorName.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('#')) {
    final hex = trimmed.substring(1);
    if (hex.length == 6 || hex.length == 8) {
      final fullHex = hex.length == 6 ? 'FF$hex' : hex;
      final value = int.tryParse(fullHex, radix: 16);
      if (value != null) return Color(value);
    }
  }
  if (trimmed.toLowerCase().startsWith('0x')) {
    final value = int.tryParse(trimmed.substring(2), radix: 16);
    if (value != null) return Color(value);
  }
  return null;
}

Color _accentFrom(Color color) {
  // Nudge toward white for a subtle lighter inner shade.
  return Color.lerp(color, Colors.white, 0.18) ?? color;
}

Color getColorFromString(String colorName, {bool accent = false}) {
  final parsed = parseColorString(colorName);
  if (parsed != null) {
    return accent ? _accentFrom(parsed) : parsed;
  }
  switch (colorName.toLowerCase()) {
    case 'red':
      return accent ? Colors.redAccent : Colors.red;
    case 'green':
      return accent ? Colors.greenAccent : Colors.green;
    case 'blue':
      return accent ? Colors.lightBlue : Colors.blue;
    case 'yellow':
      return accent ? Colors.yellowAccent : Colors.yellow;
    case 'orange':
      return accent ? Colors.orangeAccent : Colors.orange;
    case 'purple':
      return accent ? Colors.purpleAccent : Colors.purple;
    case 'lilac':
      return accent ? Colors.indigoAccent[100]! : Colors.indigo;
    case 'pink':
      return accent ? Colors.pinkAccent : Colors.pink;
    case 'white':
      return accent ? Colors.white : Colors.black12; // no whiteAccent exists
    default:
      return accent ? Colors.white70 : Colors.black12;
  }
}

bool isValidColor(String colorName) {
  if (parseColorString(colorName) != null) {
    return true;
  }
  switch (colorName.toLowerCase()) {
    case 'red':
    case 'green':
    case 'blue':
    case 'yellow':
    case 'orange':
    case 'purple':
    case 'pink':
    case 'white':
    case 'lilac':
      return true;
    default:
      return false;
  }
}
