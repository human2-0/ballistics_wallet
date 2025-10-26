import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/product_description.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sortHistoryEntries', () {
    final referenceDate = DateTime(2024, 1, 10);
    final entryA = BonusInfo(
      userId: 'user',
      bonus: 15,
      date: referenceDate,
      workingHours: 8,
      isOvertime: false,
      produced: [
        Produced(productName: 'Widget', amount: 1, ratio: 1),
      ],
    );
    final entryB = BonusInfo(
      userId: 'user',
      bonus: 20,
      date: referenceDate.subtract(const Duration(days: 1)),
      workingHours: 8,
      isOvertime: false,
      produced: [
        Produced(productName: 'Widget', amount: 1, ratio: 1),
      ],
    );
    final entryC = BonusInfo(
      userId: 'user',
      bonus: 25,
      date: referenceDate.add(const Duration(days: 2)),
      workingHours: 8,
      isOvertime: false,
      produced: [
        Produced(productName: 'Widget', amount: 1, ratio: 1),
      ],
    );

    final history = [
      MapEntry(entryA, entryA.produced.first),
      MapEntry(entryB, entryB.produced.first),
      MapEntry(entryC, entryC.produced.first),
    ];

    test('sorts by latest date first', () {
      final sorted = sortHistoryEntries(history, HistoryFilter.latest);

      expect(sorted.first.key, entryC);
      expect(sorted.last.key, entryB);
    });

    test('sorts by oldest date first', () {
      final sorted = sortHistoryEntries(history, HistoryFilter.oldest);

      expect(sorted.first.key, entryB);
      expect(sorted.last.key, entryC);
    });

    test('sorts by highest bonus with date tie-breaker', () {
      final extra = entryA.copyWith(
        bonus: entryC.bonus,
        date: entryC.date.subtract(const Duration(days: 1)),
      );
      final sorted = sortHistoryEntries(
        [
          ...history,
          MapEntry(extra, extra.produced.first),
        ],
        HistoryFilter.highestBonus,
      );

      expect(sorted.first.key, entryC);
      expect(sorted[1].key, extra);
      expect(sorted[2].key, entryB);
    });
  });
}
