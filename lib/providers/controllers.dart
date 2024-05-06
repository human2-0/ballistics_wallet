import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productNameControllerProvider =
    StateNotifierProvider<TextEditingControllerNotifier, String>(
  (ref) => TextEditingControllerNotifier(),
);

class TextEditingControllerNotifier extends StateNotifier<String> {
  TextEditingControllerNotifier() : super('') {
    _controller = TextEditingController();
    _controller.addListener(_textChanged);
  }
  late final TextEditingController _controller;

  TextEditingController get controller => _controller;

  void _textChanged() {
    state = _controller.text;
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_textChanged)
      ..dispose();
    super.dispose();
  }
}

final numberControllerProvider =
    StateNotifierProvider<NumberEditingControllerNotifier, String>(
  (ref) => NumberEditingControllerNotifier(),
);

class NumberEditingControllerNotifier extends StateNotifier<String> {
  NumberEditingControllerNotifier() : super('') {
    _controller = TextEditingController();
    _controller.addListener(_textChanged);
  }
  late final TextEditingController _controller;

  TextEditingController get controller => _controller;

  void _textChanged() {
    state = _controller.text; // Update the state with the current text value
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_textChanged)
      ..dispose();
    super.dispose();
  }
}

final allowanceControllerProvider = Provider<TextEditingController>((ref) {
  final controller = ref.watch(textEditingControllerProvider);

  // Now, in response to changes, update the controller text without resetting it
  ref.onDispose(() {
    final allowance = (ref.read(allowanceProvider) * 60).toInt();
    final formattedAllowance = allowance.toString();
    if (formattedAllowance != controller.text) {
      controller.text =
          formattedAllowance; // Direct update without recreating the controller
    }
  });

  return controller;
});

final textEditingControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final allowanceEditingControllerNotifierProvider = StateNotifierProvider<
    AllowanceEditingControllerNotifier, TextEditingController>((ref) {
  final controller = ref.watch(textEditingControllerProvider);
  return AllowanceEditingControllerNotifier(controller);
});

class AllowanceEditingControllerNotifier
    extends StateNotifier<TextEditingController> {
  AllowanceEditingControllerNotifier(TextEditingController controller)
      : super(controller) {
    state.addListener(_textChanged);
  }

  void _textChanged() {
  }

  @override
  void dispose() {
    state
      ..removeListener(_textChanged)
      ..dispose();
    super.dispose();
  }

  void updateText(String newText) {
    if (newText != state.text) {
      state.value = TextEditingValue(
        text: newText,
        selection: state.selection.isValid
            ? state.selection
            : TextSelection.collapsed(offset: newText.length),
      );
    }
  }
}

final activeTabIndexProvider = StateProvider<int>((ref) {
  return 0; // Initial index
});
