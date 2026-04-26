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
    Hive
      ..init(tempDir.path)
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
      produced: [Produced(productName: 'WidgetA', amount: 10, ratio: 1)],
    );
    final julyThird = BonusInfo(
      userId: 'tester',
      bonus: 150,
      date: DateTime(2024, 7, 3, 18, 45),
      workingHours: 6,
      isOvertime: false,
      produced: [Produced(productName: 'WidgetB', amount: 5, ratio: 1)],
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

  test('historical months count hourly pay from the 20th to the 19th', () {
    final history = buildMonthlyHistoricalData(
      hourlyRate: 10,
      now: DateTime(2025, 4, 26),
      bonusInfo: [
        BonusInfo(
          userId: 'tester',
          bonus: 10,
          date: DateTime(2025, 3, 19),
          workingHours: 5,
          isOvertime: false,
          produced: const [],
        ),
        BonusInfo(
          userId: 'tester',
          bonus: 20,
          date: DateTime(2025, 3, 20),
          workingHours: 8,
          isOvertime: false,
          produced: const [],
        ),
        BonusInfo(
          userId: 'tester',
          bonus: 30,
          date: DateTime(2025, 4, 19),
          workingHours: 4,
          isOvertime: false,
          produced: const [],
        ),
        BonusInfo(
          userId: 'tester',
          bonus: 40,
          date: DateTime(2025, 4, 20),
          workingHours: 20,
          isOvertime: false,
          produced: const [],
        ),
      ],
    );

    final april = history.singleWhere((month) => month.month == 'April 2025');

    expect(april.hoursStart, DateTime(2025, 3, 20));
    expect(april.hoursEnd, DateTime(2025, 4, 19));
    expect(april.totalHours, 12);
    expect(april.hourPay, 120);
  });

  test('bonus close dates handle every 19th weekday edge case', () {
    final cases = <DateTime, DateTime>{
      DateTime(2026): DateTime(2026, 1, 16),
      DateTime(2026, 5): DateTime(2026, 5, 18),
      DateTime(2026, 8): DateTime(2026, 8, 18),
      DateTime(2026, 2): DateTime(2026, 2, 18),
      DateTime(2026, 6): DateTime(2026, 6, 18),
      DateTime(2026, 9): DateTime(2026, 9, 18),
      DateTime(2026, 4): DateTime(2026, 4, 17),
    };

    for (final entry in cases.entries) {
      expect(
        bonusPayrollCloseDateForMonth(entry.key.year, entry.key.month),
        entry.value,
      );
    }
  });

  test(
    'historical bonus months close on the previous weekday before the 19th',
    () {
      final history = buildMonthlyHistoricalData(
        hourlyRate: 10,
        now: DateTime(2026, 4, 26),
        bonusInfo: [
          BonusInfo(
            userId: 'tester',
            bonus: 100,
            date: DateTime(2026, 3, 18),
            workingHours: 0,
            isOvertime: false,
            produced: const [],
          ),
          BonusInfo(
            userId: 'tester',
            bonus: 200,
            date: DateTime(2026, 3, 19),
            workingHours: 0,
            isOvertime: false,
            produced: const [],
          ),
          BonusInfo(
            userId: 'tester',
            bonus: 300,
            date: DateTime(2026, 4, 17),
            workingHours: 0,
            isOvertime: false,
            produced: const [],
          ),
          BonusInfo(
            userId: 'tester',
            bonus: 400,
            date: DateTime(2026, 4, 18),
            workingHours: 0,
            isOvertime: false,
            produced: const [],
          ),
        ],
      );

      final april = history.singleWhere((month) => month.month == 'April 2026');

      expect(april.bonusStart, DateTime(2026, 3, 19));
      expect(april.bonusEnd, DateTime(2026, 4, 17));
      expect(april.totalBonus, 500);
    },
  );

  test('bonus months close on Friday when the 19th is Monday', () {
    final history = buildMonthlyHistoricalData(
      hourlyRate: 10,
      now: DateTime(2026, 1, 20),
      bonusInfo: [
        BonusInfo(
          userId: 'tester',
          bonus: 10,
          date: DateTime(2025, 12, 19),
          workingHours: 0,
          isOvertime: false,
          produced: const [],
        ),
        BonusInfo(
          userId: 'tester',
          bonus: 20,
          date: DateTime(2026, 1, 16),
          workingHours: 0,
          isOvertime: false,
          produced: const [],
        ),
        BonusInfo(
          userId: 'tester',
          bonus: 40,
          date: DateTime(2026, 1, 17),
          workingHours: 0,
          isOvertime: false,
          produced: const [],
        ),
      ],
    );

    final january = history.singleWhere(
      (month) => month.month == 'January 2026',
    );

    expect(january.bonusStart, DateTime(2025, 12, 19));
    expect(january.bonusEnd, DateTime(2026, 1, 16));
    expect(january.totalBonus, 30);
  });
}
