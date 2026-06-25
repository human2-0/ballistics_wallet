import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:ballistics_wallet_flutter/ui/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('Login screen renders the unauthenticated entry point', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riveFileProvider.overrideWith((ref) => Completer<Never>().future),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Ballistics Pocket'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
