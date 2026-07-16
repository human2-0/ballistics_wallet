import 'dart:async';

import 'package:ballistics_wallet_flutter/custom_widgets/keyboard_dismiss_region.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/product_description.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet/fake_bonus_info_classes.dart';

void main() {
  testWidgets('product details open without taking keyboard focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusInfoListProvider.overrideWith((ref) => FakeBonusInfoNotifier()),
          focusedProductProvider.overrideWith(
            (ref) => ProductInfo(
              productName: 'Test product',
              imageName: 'question',
              target: 10,
              product: const [Pressing('', 0, 0)],
            ),
          ),
        ],
        child: MaterialApp(
          home: KeyboardDismissRegion(
            child: Scaffold(
              body: Consumer(
                builder:
                    (context, ref, _) => ElevatedButton(
                      onPressed:
                          () => unawaited(showProductNoteDialog(context, ref)),
                      child: const Text('Open details'),
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();

    final description = tester.widget<TextField>(find.byType(TextField));
    expect(description.readOnly, isTrue);
    expect(tester.testTextInput.hasAnyClients, isFalse);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Test product note'), findsNothing);

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.hasAnyClients, isTrue);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Test product note'), findsNothing);
    expect(tester.testTextInput.hasAnyClients, isFalse);
  });

  testWidgets('description quick inserts preserve editor focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusInfoListProvider.overrideWith((ref) => FakeBonusInfoNotifier()),
          focusedProductProvider.overrideWith(
            (ref) => ProductInfo(
              productName: 'Test product',
              imageName: 'question',
              target: 10,
              product: const [Pressing('', 0, 0)],
            ),
          ),
        ],
        child: MaterialApp(
          home: KeyboardDismissRegion(
            child: Scaffold(
              body: Consumer(
                builder:
                    (context, ref, _) => ElevatedButton(
                      onPressed:
                          () => unawaited(showProductNoteDialog(context, ref)),
                      child: const Text('Open details'),
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('• bullet'));
    await tester.pump();

    final description = tester.widget<TextField>(find.byType(TextField));
    expect(description.controller!.text, '• ');
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });
}
