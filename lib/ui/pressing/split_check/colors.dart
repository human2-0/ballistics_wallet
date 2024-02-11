import 'package:flutter/material.dart';

Color getColorFromString(String colorName, {bool accent = false}) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return accent ? Colors.red : Colors.redAccent;
    case 'green':
      return accent ? Colors.green : Colors.greenAccent;
    case 'blue':
      return accent ? Colors.blue : Colors.blueAccent;
    case 'yellow':
      return accent ? Colors.yellow : Colors.yellowAccent;
    case 'orange':
      return accent ? Colors.orange : Colors.orangeAccent;
    case 'purple':
      return accent ? Colors.purple : Colors.purpleAccent;
    case 'pink':
      return accent ? Colors.pink : Colors.pinkAccent;
    case 'white':
      return accent ? Colors.black12 : Colors.white; // no whiteAccent exists
    default:
      return accent ? Colors.black12 : Colors.white70;
  }
}
