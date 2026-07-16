import 'package:ballistics_wallet_flutter/custom_widgets/keyboard_dismiss_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dismisses focus when the application leaves the foreground', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissRegion(
          child: Scaffold(body: TextField(focusNode: focusNode)),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('dismisses focus when the user taps outside a text field', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: KeyboardDismissRegion(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                const Expanded(
                  child: ColoredBox(
                    key: Key('outside-area'),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(tester.getCenter(find.byKey(const Key('outside-area'))));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
