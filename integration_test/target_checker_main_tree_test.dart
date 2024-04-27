import 'package:ballistics_wallet_flutter/firebase_options.dart';
import 'package:ballistics_wallet_flutter/main.dart'; // Main app setup
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/overtime_shift/overtime_shift.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Mock classes
  late MockAuthRepository mockAuthRepository;
  late MockRouterConfig mockConfig;
  late MockGoRouter mockRouter;

  setUpAll(() async {
    await initHive();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize mocks
    mockAuthRepository = MockAuthRepository();
    mockConfig = MockRouterConfig();
    mockRouter = MockGoRouter(mockConfig);

    // Setup the mocks
    when(mockAuthRepository.authStateChange)
        .thenAnswer((_) => Stream.value(MockUser()));
    when(mockAuthRepository.userEmailAddress).thenReturn('test@example.com');
    when(mockAuthRepository.currentUserId).thenReturn('testUserId');
    when(mockRouter.config).thenReturn(mockConfig);
  });

  testWidgets('Ensure TargetChecker flips on horizontal drag', (tester) async {
    // Provide your app with the overridden providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          routerProvider.overrideWithValue(mockRouter),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Simulate the drag
    final gesture = await tester.startGesture(const Offset(300, 300));
    await gesture.moveBy(const Offset(-200, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    // Check the conditions
    expect(find.byType(OvertimeShift), findsOneWidget);
  });
}

class MockUser extends Mock implements User {}
class MockRouterConfig extends Mock implements RouterConfig<String> {}
class MockGoRouter extends Mock implements GoRouter {
  MockGoRouter(this.config);
  final RouterConfig<String> config;
}
class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Stream<User?> get authStateChange =>
      Stream.value(MockUser()); // Mock user or null

  @override
  String get userEmailAddress => 'test@example.com'; // Mock email

  @override
  String get currentUserId => 'testUserId'; // Mock user ID
}
