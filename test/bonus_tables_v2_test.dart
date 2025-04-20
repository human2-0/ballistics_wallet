import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/ratio_and_bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/bonus_tables_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'bonus_tables_v2_test.mocks.dart';

BonusInfoAndRatio createDummyBonusInfoAndRatio(
    {double ratio = 0.0, double allowance = 0.0,}) {
  // Create dummy data for Produced
  final dummyProduced = Produced.fromMap({
    'productName': 'Widget',
    'amount': 100,
    'ratio': ratio, // 10% ratio
    'allowance': allowance,
  });

  // Create dummy data for BonusInfo
  final dummyBonusInfo = BonusInfo.fromMap({
    'userId': 'user123',
    'bonus': 0.0,
    'date': DateTime.now(),
    'workingHours': 8.0,
    'isOvertime': true,
    'produced': [dummyProduced.toMap()],
  });

  // Create dummy data for BonusInfoAndRatio
  return BonusInfoAndRatio(
    bonusInfo: [dummyBonusInfo],
    ratio: ratio,
  );
}

/// Registers fallback values that Mockito cannot create automatically.
void registerMockitoFallbackValues() {
  // Minimal dummy instance – change the constructor if your real one differs.
  provideDummy(ProductInfo(
    productName: '',
    target: 0,
    imageName: '',
    product: [],
  ),);
}

void runTestWithoutRatio(double ratio) {
  group('BonusTableNotifier Tests with ratio $ratio', () {
    late MockRef ref;
    late BonusTableNotifier bonusTableNotifier;

    setUp(() {
      ref = MockRef();
      bonusTableNotifier = BonusTableNotifier(ref);
      provideDummy(createDummyBonusInfoAndRatio(ratio: ratio));
      provideDummy(UserState(workingHours: 7));
      when(ref.watch(targetProvider)).thenReturn(1000); // Mock a target value
    });

    test('loadInitialData loads data correctly', () async {
      await bonusTableNotifier.loadInitialData();
      // Assertions here will depend on the ratio provide
      expect(bonusTableNotifier.state.bonusData!.first.requiredAmount, 1020);
    });
  });
}

void runTestWithSomeRatio(double ratio) {
  group('BonusTableNotifier Tests with ratio $ratio', () {
    late MockRef ref;
    late BonusTableNotifier bonusTableNotifier;

    setUp(() {
      ref = MockRef();
      bonusTableNotifier = BonusTableNotifier(ref);
      provideDummy(createDummyBonusInfoAndRatio(ratio: ratio));
      provideDummy(UserState(workingHours: 7));
      when(ref.watch(targetProvider)).thenReturn(1000); // Mock a target value
    });

    test('loadInitialData loads data correctly', () async {
      await bonusTableNotifier.loadInitialData();
      // Assertions here will depend on the ratio provide
      expect(bonusTableNotifier.state.bonusData!.first.requiredAmount, 520);
      expect(bonusTableNotifier.state.bonusData!.last.requiredAmount, 1215);
    });
  });
}

void runTestWithoutRatioAndWithAnAllowance(double ratio) {
  group('BonusTableNotifier Tests with ratio $ratio', () {
    late MockRef ref;
    late BonusTableNotifier bonusTableNotifier;

    setUp(() {
      ref = MockRef();
      bonusTableNotifier = BonusTableNotifier(ref);
      provideDummy(createDummyBonusInfoAndRatio(ratio: ratio, allowance: 15));
      provideDummy(UserState(workingHours: 7));
      when(ref.watch(targetProvider)).thenReturn(1000); // Mock a target value
      when(ref.watch(allowanceProvider)).thenReturn(15 / 60);
    });

    test('loadInitialData loads data correctly', () async {
      await bonusTableNotifier.loadInitialData();
      // Assertions here will depend on the ratio provide
      expect(bonusTableNotifier.state.bonusData!.first.requiredAmount, 985);
      expect(bonusTableNotifier.state.bonusData!.last.requiredAmount, 1655);
    });
  });
}

@GenerateNiceMocks([
  MockSpec<Ref>(),
  MockSpec<BonusInfoRepository>(),
  MockSpec<BonusInfoAndRatio>(),
  MockSpec<UserRepository>(),
  MockSpec<StateNotifierProvider<BonusInfoNotifier, BonusInfoAndRatio>>(
    as: #MockBonusInfoStateNotifierProvider,
  ),
  MockSpec<StateNotifierProvider<UserNotifier, UserState>>(
    as: #MockUserNotifierStateNotifierProvider,
  ),
  MockSpec<StateProvider<double>>(as: #MockOvertimeRatioProvider),
  MockSpec<StateProvider<double?>>(as: #MockOvertimeWorkingHoursState),
  MockSpec<StateProvider<double>>(as: #MockAllowanceProvider),
  MockSpec<StateProvider<double>>(as: #MockTargetProvider),
])
void main() {
  registerMockitoFallbackValues();

  group('BonusTableNotifier Tests', () {
    late MockRef ref;
    late MockUserNotifierStateNotifierProvider mockUserNotifierState;

    setUp(() async {
      ref = MockRef();

      // Initialize the notifier with the mock
      mockUserNotifierState = MockUserNotifierStateNotifierProvider();

      provideDummy(createDummyBonusInfoAndRatio());
      provideDummy(UserState(workingHours: 7));

      // Setup the mocks
      // when(mockBonusInfoAndRatio.ratio).thenReturn(0.5); // Set the ratio here

      when(ref.watch(mockUserNotifierState))
          .thenReturn(UserState(workingHours: 7));

      when(ref.watch(targetProvider)).thenReturn(1000); // Mock a target value
    });

    runTestWithoutRatio(0);

    runTestWithSomeRatio(0.5);

    runTestWithoutRatioAndWithAnAllowance(0);
  });
}
