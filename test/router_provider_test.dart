import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_repository_test.mocks.dart';

void main() {
  test('keeps one router instance while auth state changes', () async {
    final authEvents = StreamController<User?>();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        authStateProvider.overrideWith((ref) => authEvents.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await authEvents.close();
    });

    final initialRouter = container.read(routerProvider);
    authEvents.add(MockUser(email: 'worker@gmail.com'));
    await container.pump();

    expect(container.read(routerProvider), same(initialRouter));
  });

  test('gates startup routes until Firebase restores auth', () {
    expect(
      authRedirectFor(
        authState: const AsyncLoading<User?>(),
        location: '/privacy',
      ),
      '/loading',
    );
    expect(
      authRedirectFor(
        authState: const AsyncLoading<User?>(),
        location: '/loading',
      ),
      isNull,
    );
  });

  test('routes signed-in users without resetting their active screen', () {
    final signedIn = AsyncData<User?>(MockUser(email: 'worker@gmail.com'));

    expect(authRedirectFor(authState: signedIn, location: '/loading'), '/');
    expect(authRedirectFor(authState: signedIn, location: '/privacy'), isNull);
  });

  test('rejects signed-out and lookalike-domain sessions', () {
    expect(
      authRedirectFor(authState: const AsyncData<User?>(null), location: '/'),
      '/login',
    );
    expect(
      authRedirectFor(
        authState: AsyncData<User?>(
          MockUser(email: 'worker@gmail.com.example'),
        ),
        location: '/',
      ),
      '/login',
    );
  });

  testWidgets('releases text focus when navigation replaces the screen', (
    tester,
  ) async {
    final focusNode = FocusNode();
    late BuildContext routeContext;
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [KeyboardDismissNavigatorObserver()],
        home: Builder(
          builder: (context) {
            routeContext = context;
            return Scaffold(body: TextField(focusNode: focusNode));
          },
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    unawaited(
      Navigator.of(
        routeContext,
      ).push<void>(MaterialPageRoute(builder: (_) => const Scaffold())),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}
