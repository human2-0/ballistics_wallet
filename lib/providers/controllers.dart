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
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

class ActiveIndexNotifier extends StateNotifier<int?> {
  ActiveIndexNotifier() : super(0);

  int? get activeIndex => state;

  set activeIndex(int? index) {
    if (state == index) return;
    state = index;
  }
}

final activeIndexTabProvider = StateNotifierProvider<ActiveIndexNotifier, int?>(
  (ref) => ActiveIndexNotifier(),
);
