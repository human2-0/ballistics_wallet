import 'dart:async';

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/product_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selection dismisses lookup before history refresh completes', (
    tester,
  ) async {
    final product = ProductInfo(
      productName: 'Test product',
      imageName: 'question',
      target: 42,
      product: [const Pressing('', 0, 0)],
    );
    final history = _PendingHistoryNotifier();
    final container = ProviderContainer(
      overrides: [lastSelectedProductProvider.overrideWith((ref) => history)],
    );
    addTearDown(container.dispose);
    container.read(showListProvider.notifier).state = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                final focusNode = ref.watch(focusNodeProvider);
                return Column(
                  children: [
                    TextField(focusNode: focusNode),
                    FilledButton(
                      onPressed: () => selectTargetCheckProduct(ref, product),
                      child: const Text('Select'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(container.read(focusNodeProvider).hasFocus, isTrue);

    await tester.tap(find.text('Select'));
    await tester.pump();

    expect(history.saveStarted, isTrue);
    expect(history.saveCompleted, isFalse);
    expect(container.read(focusNodeProvider).hasFocus, isFalse);
    expect(container.read(showListProvider), isFalse);
    expect(container.read(focusedProductProvider), same(product));
    expect(container.read(targetProvider), product.target);
    expect(container.read(productNameControllerProvider), product.productName);

    history.completeSave();
    await tester.pump();
    expect(history.saveCompleted, isTrue);
    expect(container.read(focusNodeProvider).hasFocus, isFalse);
  });
}

class _PendingHistoryNotifier extends LastSelectedProductNotifier {
  _PendingHistoryNotifier() : super(loadFromStorage: false);

  final Completer<void> _saveCompleter = Completer<void>();
  bool saveStarted = false;
  bool saveCompleted = false;

  @override
  Future<void> saveSelectedProduct(ProductInfo productInfo) async {
    saveStarted = true;
    await _saveCompleter.future;
    saveCompleted = true;
  }

  void completeSave() => _saveCompleter.complete();
}
