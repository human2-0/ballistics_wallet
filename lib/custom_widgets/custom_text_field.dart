import 'package:flutter/material.dart';

InputDecoration textFieldDecoration(String hintText, String labelText,
    {double borderRadius = 33.0, MaterialColor fillColor = Colors.orange,}) => InputDecoration(
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

BoxDecoration boxDecoration(
    {Color color = Colors.orange,
      double borderRadius = 33.0,
      double blurRadius = 2.5,
      Offset offset = const Offset(-2, 2.5),}) => BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.5),
        offset: offset,
      ),
    ],
  );

class CustomTextField extends StatefulWidget {

  const CustomTextField({
    required this.controller, required this.hintText, required this.labelText, super.key,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
    this.showClearIcon = false,
    this.focusNode,
  });
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final TextInputType keyboardType;
  final bool enabled;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final bool showClearIcon;
  final FocusNode? focusNode;

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    // Add listener to rebuild when text changes for the clear icon visibility
    _controller.addListener(_updateClearIconVisibility);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateClearIconVisibility);
    super.dispose();
  }

  void _updateClearIconVisibility() {
    setState(() {
      // This will trigger a rebuild when the text changes, updating the visibility of the clear icon
    });
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: boxDecoration(),
      child: TextField(
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        controller: _controller,
        decoration: textFieldDecoration(widget.hintText, widget.labelText).copyWith(
          suffixIcon: widget.showClearIcon && _controller.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600]), // Style the icon as needed
            onPressed: () {
              _controller.clear();
              widget.onChanged?.call(''); // Trigger the onChanged callback with an empty string
            },
          )
              : null,
        ),
        keyboardType: widget.keyboardType,
        textAlign: TextAlign.center,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
