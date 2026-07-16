import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const appGlassAccent = Color(0xFFC44E16);
const appGlassOnSurface = Colors.white;
const appGlassOnSurfaceMuted = Color(0xE6FFFFFF);
const appGlassIndicatorColor = Color(0x78FFFDF9);
const appGlassControlBackground = Color(0x24000000);

const appGlassTextShadows = <Shadow>[
  Shadow(color: Color(0x73000000), blurRadius: 7, offset: Offset(0, 1)),
];

const appGlassSettings = LiquidGlassSettings(
  thickness: 26,
  blur: 8,
  chromaticAberration: 0.18,
  lightIntensity: 0.65,
  refractiveIndex: 1.48,
  saturation: 0.9,
  ambientStrength: 1.05,
  glassColor: Color(0x52FFF9F5),
);
