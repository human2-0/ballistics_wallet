import 'package:flutter/material.dart';

InputDecoration textFieldDecoration(String hintText, String labelText,
    {double borderRadius = 33.0, MaterialColor fillColor = Colors.orange,}) {
  return InputDecoration(
    alignLabelWithHint: true,
    hintText: hintText,
    filled: true,
    fillColor: fillColor[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide.none,
    ),
    labelText: labelText,
    labelStyle: const TextStyle(fontSize: 18),

  );
}

BoxDecoration boxDecoration(
    {Color color = Colors.orange,
      double borderRadius = 33.0,
      double blurRadius = 2.5,
      Offset offset = const Offset(-2, 2.5),}) {
  return BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.5),
        offset: offset,
      ),
    ],
  );
}

Widget customTextField({
  required TextEditingController controller,
  required String hintText,
  required String labelText,
  TextInputType keyboardType = TextInputType.text,
  bool enabled = true,
  void Function(String)? onSubmitted,
  void Function(String)? onChanged,
}) {
  return DecoratedBox(
    decoration: boxDecoration(),
    child: TextField(
      enabled: enabled,
      controller: controller,
      decoration: textFieldDecoration(hintText, labelText),
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      onChanged: onChanged,

      onSubmitted: onSubmitted,
    ),
  );
}
