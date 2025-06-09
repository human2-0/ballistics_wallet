import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/settings.dart';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/back_up_repository.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/product_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
// Import the code under test
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_info_list.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/edit_bonus_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
// Import your mock classes
import '../auth_repository_test.mocks.dart';
import 'bonus_info_list_test.mocks.dart';
import 'fake_bonus_info_classes.dart';

// Tell Mockito to generate mocks for these classes
@GenerateNiceMocks([
  MockSpec<BonusInfoRepository>(),
  MockSpec<Box<BonusInfo>>(),
  MockSpec<ProductInfoRepository>(),
  // Here we specify onMissingStub so we don't need to manually stub addListener
  MockSpec<UserNotifier>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<BackupManager>(),
  MockSpec<UserRepository>(),
  MockSpec<ProductInfoNotifier>(),
  MockSpec<BonusInfoNotifier>(),
])
void main() {
  testWidgets('BonusInfoList shows "empty" state if box is empty',
      (tester) async {
    // 1. Create mocks
    final mockAuthRepository = MockAuthRepository();
    final mockBonusInfoRepository = MockBonusInfoRepository();
    final mockBox = MockBox();

    // 2. Stub: user ID
    when(mockAuthRepository.currentUserId).thenReturn('fakeUserId');

    // 3. Stub: openBox() returns the mockBox
    when(mockBonusInfoRepository.openBox()).thenAnswer((_) async => mockBox);

    // 4. Suppose this box is empty => no items
    when(mockBox.isEmpty).thenReturn(true);
    when(mockBox.values).thenReturn([]);

    // 5. Also stub getAllBonusInfos() => empty list
    when(mockBonusInfoRepository.getAllBonusInfos())
        .thenAnswer((_) async => []);
    // Return something for getAllRatiosToday so it doesn't crash
    when(mockBonusInfoRepository.getAllRatiosToday())
        .thenAnswer((_) async => {});

    // 6. Pump the widget with overridden providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          bonusInfoRepositoryProvider
              .overrideWithValue(mockBonusInfoRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BonusInfoList()),
        ),
      ),
    );

    // 7. Let microtasks run (BonusInfoNotifier init and load)
    await tester.pumpAndSettle();

    // 8. Verify UI is empty or shows an 'add' icon or "no data"
    //    Because you have logic that if the day's data is empty, you show an Add button or something
    //    Adapt the finder to your actual "no data" UI.
    expect(find.text('8.0 hrs'), findsNothing);
    expect(find.text('£'), findsNothing);

    // Possibly you show a plus icon or "Add" text if empty:
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
  testWidgets('BonusInfoList renders items from the BonusInfoNotifier',
      (tester) async {
    // 1) Mock repos
    final mockAuthRepository = MockAuthRepository();
    final mockBonusInfoRepository = MockBonusInfoRepository();
    final mockBox = MockBox();

    // 2) A fixed date so the filtering matches
    final testDate = DateTime(2023);

    // 3) A sample BonusInfo with the same date
    final sampleBonusInfo = BonusInfo(
      userId: 'fakeUserId',
      id: 'uniqueID',
      date: testDate,
      workingHours: 8,
      bonus: 100,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetA', amount: 10, ratio: 0),
        Produced(productName: 'WidgetB', amount: 5, ratio: 0),
      ],
    );

    // 4) Stub repository/hive methods
    when(mockAuthRepository.currentUserId).thenReturn('fakeUserId');
    when(mockBonusInfoRepository.openBox()).thenAnswer((_) async => mockBox);
    when(mockBox.isEmpty).thenReturn(false);
    when(mockBox.values).thenReturn([sampleBonusInfo]);
    when(mockBonusInfoRepository.getAllBonusInfos())
        .thenAnswer((_) async => [sampleBonusInfo]);
    when(mockBonusInfoRepository.getAllRatiosToday())
        .thenAnswer((_) async => {'widgeta': 1.0});

    // 5) Pump the widget, override the date to match sampleBonusInfo.date
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // So the items pass the "isSameDay" check
          selectedDateProvider.overrideWith((_) => testDate),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          bonusInfoRepositoryProvider
              .overrideWithValue(mockBonusInfoRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: BonusInfoList())),
      ),
    );

    // 6) Let microtask queue empty so init() -> loadBonusInfos() completes
    await tester.pumpAndSettle();

    // 7) Expect the UI to have “8.0 hrs” from sampleBonusInfo
    expect(find.text('8.0 hrs'), findsOneWidget);
    expect(find.text('£100.00'), findsOneWidget);
    expect(find.text('WidgetA'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('BonusInfoList opens AddBonusInfoModal and saves data',
      (tester) async {
    final goRouter = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: BonusInfoList()),
        ),
      ],
    );

    // 1. Create mock repositories
    final mockAuth = MockAuthRepository();
    final mockProductInfoRepo = MockProductInfoRepository();
    final mockBonusInfoRepo = MockBonusInfoRepository();
    final mockUserRepo = MockUserRepository();
    final mockUserNotifier = MockUserNotifier();
    final mockBackupNotifier = MockBackupManager();

    // 2. Stub Auth
    when(mockAuth.currentUserId).thenReturn('fakeUserId');
    when(mockUserRepo.getUserData('fakeUserId')).thenAnswer(
      (_) async => UserSettings(
        userId: 'fakeUserId',
        workingHours: 7,
        realWorkingHours: 8,
        backup: false,
      ),
    );

    // 3. Stub ProductInfoRepo to return some product data
    final sampleProducts = [
      ProductInfo(
        productName: 'WidgetA',
        imageName: 'WidgetA',
        target: 100,
        product: [const Pressing('PressingX', 0, 0)],
      ),
      ProductInfo(
        productName: 'WidgetB',
        imageName: 'WidgetB',
        target: 50,
        product: [const Pressing('PressingY', 0, 0)],
      ),
    ];
    when(mockProductInfoRepo.fetchProductInfo())
        .thenAnswer((_) async => sampleProducts);

    // 4. Stub the BonusInfoRepo so no real Hive calls occur
    final mockBox = MockBox();
    when(mockBonusInfoRepo.openBox()).thenAnswer((_) async => mockBox);
    when(mockBox.isEmpty).thenReturn(true);
    when(mockBox.values).thenReturn([]);

    when(mockBonusInfoRepo.getAllBonusInfos()).thenAnswer((_) async => []);
    when(mockBonusInfoRepo.getAllRatiosToday()).thenAnswer((_) async => {});
    when(mockBonusInfoRepo.addBonusInfo(any))
        .thenAnswer((_) async => 'Product added.');

    final testDate = DateTime(2023);

    // 5. Stub UserNotifier's state and methods
    when(mockUserNotifier.state).thenReturn(
      UserState(
        userId: 'fakeId',
        backup: false,
        realWorkingHours: 8,
        workingHours: 8,
        paidBreaks: false,
        hourlyRate: 100,
        avatarUrl: '',
        askForBackup: false,
        // Initialize other fields if necessary
      ),
    );

    // Stub addListener to prevent errors
    when(mockUserNotifier.addListener(any,
            fireImmediately: anyNamed('fireImmediately'),),)
        .thenAnswer((_) => () {});

    final bonusCalculatorOverride = Provider.family<double, double>(
      (ref, sumOfRatios) =>
          123.45, // or compute a value based on sumOfRatios if needed
    );

    // 6. Pump our widget in a test environment
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          authRepositoryProvider.overrideWithValue(mockAuth),
          bonusCalculator.overrideWithProvider(bonusCalculatorOverride.call),
          productInfoRepo.overrideWithValue(mockProductInfoRepo),
          bonusInfoRepositoryProvider.overrideWithValue(mockBonusInfoRepo),
          userNotifierProvider.overrideWith((ref) => FakeUserNotifier()),
          backupManagerProvider.overrideWith((ref) => mockBackupNotifier),
          selectedDateProvider.overrideWith((ref) => testDate),
          productInfoRepo
              .overrideWithValue(FakeProductInfoRepository(sampleProducts)),
          bonusInfoListProvider.overrideWith((ref) => FakeBonusInfoNotifier()),
          // Add any other necessary overrides here
        ],
        child: MaterialApp.router(
          routerConfig: goRouter,
        ),
      ),
    );

    // 7. Let everything settle
    await tester.pumpAndSettle();

    // 8. Because the list is empty, we should see the plus icon (keyed as 'addBonusIcon')
    final addIconFinder = find.byKey(const Key('addBonusIcon'));
    expect(addIconFinder, findsOneWidget);

    // 9. Tap the plus icon -> showModalBottomSheet for AddBonusInfoModal
    await tester.tap(addIconFinder);
    await tester.pumpAndSettle();

    // 10. The bottom sheet is now visible. Let's fill some fields using the keys we added:
    final productNameField = find.byKey(const Key('productNameField'));
    final amountField = find.byKey(const Key('amountField'));
    final workingHoursField = find.byKey(const Key('workingHoursField'));
    final addBonusButton = find.byKey(const Key('addBonusButton'));

    // Make sure they're all present
    expect(productNameField, findsOneWidget);
    expect(amountField, findsOneWidget);
    expect(workingHoursField, findsOneWidget);
    expect(addBonusButton, findsOneWidget);

    // Enter text
    await tester.enterText(productNameField, 'WidgetA');
    await tester.enterText(amountField, '50');
    await tester.enterText(workingHoursField, '8');

    // 11. Tap 'Add Bonus'
    await tester.tap(addBonusButton);

    // Because your modal closes via `addPostFrameCallback(...)` we need extra pumps:
    await tester.pump(); // start the close
    await tester
        .pump(const Duration(milliseconds: 100)); // let the callback run
    await tester.pumpAndSettle(); // finish animations and frame callbacks

    // 12. The bottom sheet should close, and 'addBonusButton' should no longer be in the widget tree
    expect(find.byKey(const Key('addBonusButton')), findsNothing);

    // 14. Suppose we now return a newly added item from getAllBonusInfos():
    final newItem = BonusInfo(
      userId: 'fakeUserId',
      id: 'someID',
      date: testDate,
      workingHours: 8,
      bonus: 123.45,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetA', amount: 50, ratio: 0.5),
      ],
    );
    when(mockBonusInfoRepo.getAllBonusInfos())
        .thenAnswer((_) async => [newItem]);

    // If your code calls loadBonusInfos() automatically after adding,
    // let's let it settle:
    await tester.pumpAndSettle();

    // 15. Now we should see an item with "8.0 hrs" and "£123.45"
    expect(find.text('8.0 hrs'), findsOneWidget);
    expect(find.text('£123.45'), findsOneWidget);
  });

  testWidgets('EditBonusInfoModal updates bonus info correctly',
      (tester) async {
    final sampleProducts = [
      ProductInfo(
        productName: 'WidgetA',
        imageName: 'WidgetA',
        target: 100,
        product: [const Pressing('PressingX', 0, 0)],
      ),
      ProductInfo(
        productName: 'WidgetB',
        imageName: 'WidgetB',
        target: 50,
        product: [const Pressing('PressingY', 0, 0)],
      ),
    ];

    final mockAuth = MockAuthRepository();
    final mockProductInfoRepo = MockProductInfoRepository();
    final mockBonusInfoRepo = MockBonusInfoRepository();
    final mockUserRepo = MockUserRepository();
    final mockBackupNotifier = MockBackupManager();
    final testDate = DateTime(2023);
    // Create a sample BonusInfo instance to edit.
    final sampleBonusInfo = BonusInfo(
      userId: 'fakeUserId',
      id: 'editTestID',
      date: testDate,
      workingHours: 8,
      bonus: 100,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetA', amount: 10, ratio: 0),
      ],
    );

    // Initialize our fake notifier and add the sample bonus info.
    final fakeBonusNotifier = FakeBonusInfoNotifier();
    await fakeBonusNotifier.addBonusInfo(sampleBonusInfo);

    // Build a widget that has a button to open the EditBonusInfoModal.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the bonusInfoListProvider with our fake notifier.
          userRepositoryProvider.overrideWithValue(mockUserRepo),
          authRepositoryProvider.overrideWithValue(mockAuth),
          productInfoRepo.overrideWithValue(mockProductInfoRepo),
          bonusInfoRepositoryProvider.overrideWithValue(mockBonusInfoRepo),
          userNotifierProvider.overrideWith((ref) => FakeUserNotifier()),
          backupManagerProvider.overrideWith((ref) => mockBackupNotifier),
          selectedDateProvider.overrideWith((ref) => testDate),
          productInfoRepo
              .overrideWithValue(FakeProductInfoRepository(sampleProducts)),
          bonusInfoListProvider.overrideWith((ref) => FakeBonusInfoNotifier()),
          bonusInfoListProvider.overrideWith((ref) => fakeBonusNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('openEditModalButton'),
                onPressed: () async {
                  await showModalBottomSheet<Widget>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => EditBonusInfoModal(
                      bonusInfo: sampleBonusInfo,
                      index: 0,
                    ),
                  );
                },
                child: const Text('Open Edit Modal'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap the button to open the edit modal.
    await tester.tap(find.byKey(const Key('openEditModalButton')));
    await tester.pumpAndSettle();

    // Locate the text fields in the modal by their keys.
    // (Ensure that in your EditBonusInfoModal you assign these keys accordingly.)
    final workingHoursField = find.byKey(const Key('editWorkingHoursField'));
    final bonusField = find.byKey(const Key('editBonusField'));
    final productNameField = find.byKey(const Key(
        'editProductNameField_0',),); // Added key to typeahead TextField.
    final amountField = find.byKey(const Key('editAmountField_0'));
    final saveButton = find.widgetWithText(ElevatedButton, 'Save');

    // Verify that all the fields and the save button are present.
    expect(workingHoursField, findsOneWidget);
    expect(bonusField, findsOneWidget);
    expect(productNameField, findsOneWidget);
    expect(amountField, findsOneWidget);
    expect(saveButton, findsOneWidget);

    // Simulate the user editing the fields.
    await tester.enterText(workingHoursField, '9');
    await tester.enterText(bonusField, '150');
    await tester.enterText(productNameField, 'WidgetB');
    await tester.enterText(amountField, '20');

    // Tap the Save button.
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Ensure the modal is closed.
    expect(find.byType(EditBonusInfoModal), findsNothing);

    // Verify that the fake notifier now holds the updated bonus info.
    final updatedBonus = fakeBonusNotifier.state.bonusInfo.first;
    expect(updatedBonus.workingHours, 9);
    expect(updatedBonus.bonus, 150);
    expect(updatedBonus.produced.first.productName, 'WidgetB');
    expect(updatedBonus.produced.first.amount, 20);
  });
}
