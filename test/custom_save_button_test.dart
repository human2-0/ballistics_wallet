import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/custom_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallet/fake_bonus_info_classes.dart';
import 'wallet/bonus_info_list_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<BackupManager>(),
])
void main() {
  testWidgets('CustomSaveButton saves bonus on tap', (tester) async {
    final mockAuth = MockAuthRepository();
    final mockBackup = MockBackupManager();
    when(mockAuth.currentUserId).thenReturn('user123');
    when(mockBackup.state).thenReturn(BackupState());

    final fakeBonusNotifier = FakeBonusInfoNotifier();
    final fakeUserNotifier = FakeUserNotifier();
    fakeUserNotifier.state =
        fakeUserNotifier.state.copyWith(backup: true, askForBackup: true);

    final overrides = [
      bonusInfoListProvider.overrideWith((ref) => fakeBonusNotifier),
      userNotifierProvider.overrideWith((ref) => fakeUserNotifier),
      authRepositoryProvider.overrideWithValue(mockAuth),
      backupManagerProvider.overrideWith((ref) => mockBackup),
      focusedProductProvider.overrideWith(
        (ref) => ProductInfo(
          productName: 'WidgetA',
          target: 100,
          imageName: 'w',
          product: const [],
        ),
      ),
      numberControllerProvider.overrideWithProvider(StateProvider((ref) => '5')),
      targetProvider.overrideWith((ref) => 100),
      allowanceProvider.overrideWithProvider(StateProvider((ref) => 0.0)),
      bonusCalculator.overrideWithProvider(
        Provider.family<double, double>((ref, ratio) => 1.0).call,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: Scaffold(body: CustomSaveButton()),
        ),
      ),
    );

    await tester.pump();
    expect(fakeBonusNotifier.state.bonusInfo, isEmpty);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(fakeBonusNotifier.state.bonusInfo.length, 1);
    expect(find.text('Fake bonus added'), findsOneWidget);
  });

  testWidgets('CustomSaveButton disabled when product is empty', (tester) async {
    final mockAuth = MockAuthRepository();
    final mockBackup = MockBackupManager();
    when(mockAuth.currentUserId).thenReturn('user123');
    when(mockBackup.state).thenReturn(BackupState());

    final fakeBonusNotifier = FakeBonusInfoNotifier();
    final fakeUserNotifier = FakeUserNotifier();
    fakeUserNotifier.state =
        fakeUserNotifier.state.copyWith(backup: true, askForBackup: true);

    final overrides = [
      bonusInfoListProvider.overrideWith((ref) => fakeBonusNotifier),
      userNotifierProvider.overrideWith((ref) => fakeUserNotifier),
      authRepositoryProvider.overrideWithValue(mockAuth),
      backupManagerProvider.overrideWith((ref) => mockBackup),
      focusedProductProvider.overrideWith(
        (ref) => ProductInfo(
          productName: '',
          target: 100,
          imageName: 'w',
          product: const [],
        ),
      ),
      numberControllerProvider.overrideWithProvider(StateProvider((ref) => '5')),
      targetProvider.overrideWith((ref) => 100),
      allowanceProvider.overrideWithProvider(StateProvider((ref) => 0.0)),
      bonusCalculator.overrideWithProvider(
        Provider.family<double, double>((ref, ratio) => 1.0).call,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: Scaffold(body: CustomSaveButton()),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(fakeBonusNotifier.state.bonusInfo, isEmpty);
  });
}
