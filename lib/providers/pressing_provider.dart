import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final numberFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final numberFocusNode = FocusNode();
  ref.onDispose(() {
    numberFocusNode.dispose();
  });
  return numberFocusNode;
});

final allowanceFocusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final allowanceFocusNode = FocusNode();
  ref.onDispose(() {
    allowanceFocusNode.dispose();
  });
  return allowanceFocusNode;
});




final showListProvider = StateProvider<bool>((ref) => false);

class FocusNotifier extends StateNotifier<bool> {
  FocusNotifier() : super(false);

  void setFocus(bool focus) {
    state = focus;
  }
}

final focusNodeProvider = Provider.autoDispose<FocusNode>((ref) {
  final focusNode = FocusNode();
  final focusNotifier = ref.read(focusNotifierProvider.notifier);

  focusNode.addListener(() {
    focusNotifier.setFocus(focusNode.hasFocus);
  });

  ref.onDispose(() {
    focusNode.removeListener(() {
      focusNotifier.setFocus(focusNode.hasFocus);
    });
    focusNode.dispose();
  });

  return focusNode;
});

final focusNotifierProvider = StateNotifierProvider<FocusNotifier, bool>((ref) {
  return FocusNotifier();
});



final textEditingControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

// Similarly for other controllers
final numberControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

final allowanceControllerProvider = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
  });
  return controller;
});

class BonusTableSelector extends StateNotifier<bool> {
  BonusTableSelector() : super(false);

  void toggle() {
    state = !state;
    print('State is now: $state');
  }
}

final bonusTableSelectorProvider =
StateNotifierProvider<BonusTableSelector, bool>((ref) {
  return BonusTableSelector();
});


