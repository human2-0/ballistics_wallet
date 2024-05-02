import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
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

BonusInfoAndRatio createDummyBonusInfoAndRatio({double ratio = 0}) {
  // Create dummy data for Produced
  final dummyProduced = Produced.fromMap({
    'productName': 'Widget',
    'amount': 100,
    'ratio': ratio, // 10% ratio
    'allowance': 0,
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
  );
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
  group('BonusTableNotifier Tests', () {
    late MockRef ref;
    late BonusTableNotifier bonusTableNotifier;
    late MockUserNotifierStateNotifierProvider mockUserNotifierState;

    setUp(() {
      ref = MockRef();
      // Initialize the notifier with the mock
      bonusTableNotifier = BonusTableNotifier(ref);
      mockUserNotifierState = MockUserNotifierStateNotifierProvider();

      provideDummy(createDummyBonusInfoAndRatio());
      provideDummy(UserState(workingHours: 7));

      // Setup the mocks
      // when(mockBonusInfoAndRatio.ratio).thenReturn(0.5); // Set the ratio here

      when(ref.watch(mockUserNotifierState))
          .thenReturn(UserState(workingHours: 7));

      when(ref.watch(targetProvider)).thenReturn(1000); // Mock a target value
    });

    test('loadInitialData loads data correctly', () async {
      // Arrange
      // Assuming getBonuses() and other methods return expected values correctly mocked

      // Act
      await bonusTableNotifier.loadInitialData();

      // Assert
      // Check if the state is updated correctly
      expect(bonusTableNotifier.state.isLoading, false);
      expect(bonusTableNotifier.state.bonusData!.first.requiredAmount, 1020);
      expect(bonusTableNotifier.state.bonusData!.last.requiredAmount, 1715);
      // Further assertions can be added to check for correct values in the state
    });

    test('loadInitialData with a higher ratio', () async {
      print(ref.watch(bonusInfoListProvider).ratio);

      // Act
      await bonusTableNotifier.loadInitialData();

      // Assert
      expect(bonusTableNotifier.state.isLoading, false);
      expect(bonusTableNotifier.state.bonusData!.first.requiredAmount, 510);
      // Additional assertions as needed
    });
  });
}
