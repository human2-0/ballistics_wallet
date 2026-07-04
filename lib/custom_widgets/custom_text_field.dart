import 'package:flutter/material.dart';

InputDecoration textFieldDecoration(
  String hintText,
  String labelText, {
  double borderRadius = 33.0,
  MaterialColor fillColor = Colors.orange,
}) => InputDecoration(
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

BoxDecoration boxDecoration({
  Color color = Colors.orange,
  double borderRadius = 33.0,
  double blurRadius = 2.5,
  Offset offset = const Offset(-2, 2.5),
}) => BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), offset: offset)],
);

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required this.controller,
    required this.hintText,
    required this.labelText,
    super.key,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
    this.showClearIcon = false,
    this.focusNode,
    this.selectAllOnFocus = false,
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
  final bool selectAllOnFocus;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_selectTextOnFocus);
    // Add listener to rebuild when text changes for the clear icon visibility
    widget.controller.addListener(_updateClearIconVisibility);
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateClearIconVisibility);
      widget.controller.addListener(_updateClearIconVisibility);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_selectTextOnFocus);
      if (_ownsFocusNode) _focusNode.dispose();
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_selectTextOnFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_selectTextOnFocus);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    widget.controller.removeListener(_updateClearIconVisibility);
    super.dispose();
  }

  void _selectTextOnFocus() {
    if (!widget.selectAllOnFocus || !_focusNode.hasFocus) return;
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  void _updateClearIconVisibility() {
    if (!mounted) return;
    setState(() {
      // This will trigger a rebuild when the text changes, updating the visibility of the clear icon
    });
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: boxDecoration(),
    child: TextField(
      focusNode: _focusNode,
      enabled: widget.enabled,
      controller: widget.controller,
      decoration: textFieldDecoration(
        widget.hintText,
        widget.labelText,
      ).copyWith(
        suffixIcon:
            widget.showClearIcon && widget.controller.text.isNotEmpty
                ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                  ), // Style the icon as needed
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call(
                      '',
                    ); // Trigger the onChanged callback with an empty string
                  },
                )
                : null,
      ),
      keyboardType: widget.keyboardType,
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      onChanged: (value) {
        // Pass change upstream if caller supplied a handler
        widget.onChanged?.call(value);
      },
      onSubmitted: widget.onSubmitted ?? (_) => _focusNode.unfocus(),
    ),
  );
}
