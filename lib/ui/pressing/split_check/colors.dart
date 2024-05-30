import 'package:flutter/material.dart';

Color getColorFromString(String colorName, {bool accent = false}) {
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
