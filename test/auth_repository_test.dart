import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_repository_test.mocks.dart'; // Import the generated mocks

class MockUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        // Override toastMessageProvider with a StateNotifier for testing
        toastMessageProvider.overrideWith((ref) => ''),

      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('loginWithGoogle success', () async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => MockUserCredential());

    final loginController = container.read(loginControllerProvider.notifier);

    await loginController.loginWithGoogle();

    expect(container.read(loginControllerProvider), isA<LoginStateSuccess>());
    verify(mockAuthRepository.signInWithGoogle()).called(1);

    // Access the state of the StateNotifier for toastMessage
    expect(container.read(toastMessageProvider.notifier).state, "Welcome on board, Lush's Warrior!");


  });

  test('loginWithGoogle failure', () async {
    when(mockAuthRepository.signInWithGoogle()).thenThrow(const FormatException('Test Exception')); // Correct: Use thenThrow for failure

    final loginController = container.read(loginControllerProvider.notifier);

    await loginController.loginWithGoogle();
    await container.pump(); // Wait for state update

    final loginState = container.read(loginControllerProvider);
    expect(loginState, isA<LoginStateError>());
    expect((loginState as LoginStateError).error, 'FormatException: Test Exception'); // Check error message

    verify(mockAuthRepository.signInWithGoogle()).called(1);
  });
}
