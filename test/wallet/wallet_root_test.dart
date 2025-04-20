// test/wallet_root_test.dart
import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../auth_repository_test.mocks.dart';
import 'fake_bonus_info_classes.dart'; // <- re‑use the fakes you already wrote

// ─────────────────────────────────────────────────────────────────────────
// Helper fakes that let us tweak the hourly‑rate easily in these tests.
// ─────────────────────────────────────────────────────────────────────────


void main() {
  late FakeBonusInfoNotifier fakeBonusNotifier;
  late FakeUserNotifier      fakeUserNotifier;
  late MockAuthRepository mockAuthRepository;

  /// Builds the WalletRoot inside a ProviderScope that injects the fakes.
  Future<void> pumpWalletRoot(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bonusInfoListProvider.overrideWith((_) => fakeBonusNotifier),
          userNotifierProvider.overrideWith((_) => fakeUserNotifier),
        ],
        child: MaterialApp(
          home: WalletRoot(onNotification: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    fakeBonusNotifier = FakeBonusInfoNotifier();
    fakeUserNotifier  = FakeUserNotifier();
    mockAuthRepository = MockAuthRepository();
  });

  testWidgets('WalletRoot shows zero totals when there is no data',
      (tester) async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) => Future.error(Exception('Test Exception')));


    await pumpWalletRoot(tester);

    expect(find.text('Hours\n0.00'), findsOneWidget);
    expect(find.text('Bonus\n£0.00'), findsOneWidget);
    expect(find.text('Salary £0.00'), findsOneWidget);
  });

  testWidgets('WalletRoot updates totals after a bonus is added',
      (tester) async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) => Future.error(Exception('Test Exception')));
    await pumpWalletRoot(tester);

    // 1️⃣  Nothing yet – still zeros.
    expect(find.text('Bonus\n£0.00'), findsOneWidget);

    // 2️⃣  Add a sample bonus record.
    final sample = BonusInfo(
      userId: 'fakeId',
      id: 'sample',
      date: DateTime(2025),
      workingHours: 8,
      bonus: 150,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetA', amount: 10, ratio: 0),
      ],
    );

    // Because addBonusInfo is async, wrap in runAsync.
    await tester.runAsync(() => fakeBonusNotifier.addBonusInfo(sample));
    await tester.pumpAndSettle();

    // 3️⃣  Totals should now be: hours 8, bonus £150, salary £(150+8*100)=£950
    expect(find.text('Hours\n8.00'), findsOneWidget);
    expect(find.text('Bonus\n£150.00'), findsOneWidget);
    expect(find.text('Salary £950.00'), findsOneWidget);
  });

  testWidgets('WalletRoot reacts when hourly rate changes', (tester) async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) => Future.error(Exception('Test Exception')));
    await pumpWalletRoot(tester);

    // Add two different BonusInfo items (total bonus £200, total hours 12).
    final items = [
      BonusInfo(
        userId: 'fakeId',
        id: 'a',
        date: DateTime(2025, 2, 2),
        workingHours: 8,
        bonus: 100,
        isOvertime: false,
        produced: const [],
      ),
      BonusInfo(
        userId: 'fakeId',
        id: 'b',
        date: DateTime(2025, 2, 3),
        workingHours: 4,
        bonus: 100,
        isOvertime: false,
        produced: const [],
      ),
    ];

    await tester.runAsync(() async {
      for (final b in items) {
        await fakeBonusNotifier.addBonusInfo(b);
      }
    });
    await tester.pumpAndSettle();

    // Currently: hourlyRate = 100  -> salary  (200 + 12*100) = 1400
    expect(find.text('Salary £1400.00'), findsOneWidget);

    // Now drop hourlyRate to 10 and watch the UI change.
    fakeUserNotifier.state =
        fakeUserNotifier.state.copyWith(hourlyRate: 10);
    await tester.pumpAndSettle();

    // New salary should be 200 + 12*10 = 320
    expect(find.text('Salary £320.00'), findsOneWidget);
  });
}
