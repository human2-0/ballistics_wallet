import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates input ownership and dismisses on done', (tester) async {
    final firstController = TextEditingController();
    final secondController = TextEditingController();
    final firstFocusNode = FocusNode();
    final secondFocusNode = FocusNode();
    var useSecondInput = false;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return CustomTextField(
                controller: useSecondInput ? secondController : firstController,
                focusNode: useSecondInput ? secondFocusNode : firstFocusNode,
                hintText: 'Value',
                labelText: 'Value',
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(firstFocusNode.hasFocus, isTrue);

    rebuild(() => useSecondInput = true);
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(secondFocusNode.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(secondFocusNode.hasFocus, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();
    secondController.dispose();
    firstFocusNode.dispose();
    secondFocusNode.dispose();
  });
}
