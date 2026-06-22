import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:expressions/expressions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalculatorField extends ConsumerStatefulWidget {
  const CalculatorField({
    required this.focusNode,
    required this.controller,
    required this.ref,
    required this.focusedProductName,
    required this.workingHours,
    required this.allowance,
    super.key,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final WidgetRef ref;
  final String focusedProductName;
  final double workingHours;
  final double allowance;

  @override
  ConsumerState<CalculatorField> createState() => _CalculatorFieldState();
}

class _CalculatorFieldState extends ConsumerState<CalculatorField> {
  late OverlayEntry _overlayEntry;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (widget.focusNode.hasFocus && !_isOverlayVisible) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry);
      _isOverlayVisible = true;
    } else if (!widget.focusNode.hasFocus) {
      if (_isOverlayVisible) {
        _overlayEntry.remove();
        _isOverlayVisible = false;
      }
      _evaluateAndTriggerUpdate(); // Evaluate when focus is lost
    }
  }

  OverlayEntry _createOverlayEntry() => OverlayEntry(
    builder:
        (context) => Positioned(
          bottom:
              MediaQuery.of(
                context,
              ).viewInsets.bottom, // Position above the keyboard
          left: 0,
          right: 0,
          child: Material(
            elevation: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildOperatorButton('+'),
                  _buildOperatorButton('-'),
                  _buildOperatorButton('*'),
                  _buildOperatorButton('/'),
                ],
              ),
            ),
          ),
        ),
  );
  Widget _buildOperatorButton(String operator) => IconButton(
    icon: Container(
      padding: const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33),
        color: Colors.white,
      ),
      child: Text(
        operator,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
    onPressed: () => _appendText(operator),
  );

  void _appendText(String text) {
    final currentText = widget.controller.text;
    final newText = currentText + text;
    widget.controller.value = widget.controller.value.copyWith(
      text: newText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      ),
    );
  }

  void _evaluateAndTriggerUpdate() {
    final expression =
        widget.controller.text.isEmpty
            ? '0'
            : widget.controller.text; // Check if the text is empty
    try {
      final exp = Expression.parse(expression);
      const evaluator = CustomExpressionEvaluator();
      final result = evaluator.eval(exp, {});
      widget.controller.text = result.toString();

      // Trigger the onChanged functionality with the result
      _triggerOnChanged(result.toString());
    } on FormatException {
      // Handle parsing error or simply do nothing to avoid updating the controller with incorrect data
      // Optionally, you might want to handle errors by displaying an error or logging it
      widget.controller.text =
          '0'; // Set text to "0" if there's a parsing error
      _triggerOnChanged('0');
    }
  }

  void _triggerOnChanged(String value) {
    // Call the updateRatio with the newly evaluated result
    widget.ref
        .read(bonusInfoListProvider.notifier)
        .updateRatio(
          widget.focusedProductName.toLowerCase(),
          widget.ref.read(targetProvider),
          int.tryParse(value) ?? 0, // Ensure to handle null and parsing errors
          widget.workingHours,
          widget.allowance,
        );
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    focusNode: widget.focusNode,
    controller: widget.controller,
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      alignLabelWithHint: true,
      labelText: 'Amount pressed',
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      fillColor: Colors.yellowAccent[100],
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(33),
        borderSide: BorderSide.none,
      ),
      prefixIcon: const Icon(Icons.calculate_rounded),
      suffixIcon: Visibility(
        visible: widget.focusNode.hasFocus,
        child: IconButton(
          icon: const Icon(Icons.keyboard_hide),
          onPressed: () {
            dismissTargetCheckInputs(widget.ref);
          },
        ),
      ),
    ),
    keyboardType: TextInputType.number, // Custom input type
    textInputAction: TextInputAction.done,
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(r'[0-9+\-*/%.]'),
      ), // Allow digits and operators
    ],
    onFieldSubmitted: (value) {
      dismissTargetCheckInputs(widget.ref);
    },
  );

  @override
  void dispose() {
    if (_isOverlayVisible) {
      _overlayEntry.remove();
    }
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }
}

class CustomExpressionEvaluator extends ExpressionEvaluator {
  const CustomExpressionEvaluator();

  @override
  dynamic eval(Expression expression, Map<String, dynamic> context) {
    if (expression is BinaryExpression) {
      final left = eval(expression.left, context);
      final right = eval(expression.right, context);

      switch (expression.operator) {
        case '/':
          if (left is num && right is num) {
            // Use integer division operator to always round down
            return left ~/ right;
          } else {
            throw const FormatException(
              'Operands must be numbers for division operation',
            );
          }
        case '%':
          if (left is num && right is num) {
            // Ensure integer division for modulo
            return (left % right).toInt();
          } else {
            throw const FormatException(
              'Operands must be numbers for modulo operation',
            );
          }
        default:
          break;
      }
    }

    return super.eval(expression, context);
  }
}
