import 'dart:io';

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/custom_date_range.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('wallet_provider_test');
    Hive..init(tempDir.path)
    ..registerAdapter(ProducedAdapter())
    ..registerAdapter(BonusInfoAdapter())
    ..registerAdapter(CustomDateRangeAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    if (Hive.isBoxOpen('bonusInfoBox')) {
      await Hive.box<BonusInfo>('bonusInfoBox').clear();
    }
    if (Hive.isBoxOpen('customDateRangeBox')) {
      await Hive.box<CustomDateRange>('customDateRangeBox').clear();
    }
    await Hive.deleteBoxFromDisk('bonusInfoBox');
    await Hive.deleteBoxFromDisk('customDateRangeBox');
  });

  test('totals include entries that fall on the selected end date', () async {
    final repository = BonusInfoRepository();
    final notifier = BonusInfoNotifier(repository, 'tester');

    // Allow the async initialization microtask to complete.
    await Future<void>.delayed(Duration.zero);

    final julyFirst = BonusInfo(
      userId: 'tester',
      bonus: 100,
      date: DateTime(2024, 7, 1, 10, 30),
      workingHours: 8,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetA', amount: 10, ratio: 1),
      ],
    );
    final julyThird = BonusInfo(
      userId: 'tester',
      bonus: 150,
      date: DateTime(2024, 7, 3, 18, 45),
      workingHours: 6,
      isOvertime: false,
      produced: [
        Produced(productName: 'WidgetB', amount: 5, ratio: 1),
      ],
    );

    await notifier.addBonusInfo(julyFirst);
    await notifier.addBonusInfo(julyThird);

    final rangeBox = await Hive.openBox<CustomDateRange>('customDateRangeBox');
    await rangeBox.put(
      'myCustomDateRange',
      CustomDateRange(
        hoursStart: DateTime(2024, 7),
        hoursEnd: DateTime(2024, 7, 3),
        bonusStart: DateTime(2024, 7),
        bonusEnd: DateTime(2024, 7, 3),
      ),
    );

    final totalHours = await notifier.getTotalWorkingHours();
    final totalBonus = await notifier.getTotalBonus();

    expect(totalHours, julyFirst.workingHours + julyThird.workingHours);
    expect(totalBonus, julyFirst.bonus + julyThird.bonus);

    notifier.dispose();
  });
}
