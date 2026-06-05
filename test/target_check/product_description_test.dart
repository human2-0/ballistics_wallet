import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:flutter_test/flutter_test.dart';

import '../wallet/fake_bonus_info_classes.dart';

void main() {
  BonusInfo buildBonus({required String productName, required DateTime date}) =>
      BonusInfo(
        userId: 'user',
        bonus: 10,
        date: date,
        workingHours: 8,
        isOvertime: false,
        produced: [Produced(productName: productName, amount: 1, ratio: 1)],
      );

  group('BonusInfoNotifier.getProductHistory', () {
    test('matches product names case- and whitespace-insensitively', () async {
      final notifier = FakeBonusInfoNotifier();
      await Future<void>.delayed(Duration.zero);

      final entries = [
        buildBonus(productName: 'Widget', date: DateTime(2024)),
        buildBonus(productName: 'widget', date: DateTime(2024, 1, 2)),
        buildBonus(productName: '  widget  ', date: DateTime(2024, 1, 3)),
        buildBonus(productName: 'WiDgEt', date: DateTime(2024, 1, 4)),
      ];

      for (final entry in entries) {
        await notifier.addBonusInfo(entry);
      }

      final history = notifier.getProductHistory(' widget ');

      expect(history.length, entries.length);
      expect(
        history.map((entry) => entry.date).toSet(),
        entries.map((entry) => entry.date).toSet(),
      );
    });

    test('excludes entries for other products', () async {
      final notifier = FakeBonusInfoNotifier();
      await Future<void>.delayed(Duration.zero);

      final widgetEntry = buildBonus(
        productName: 'Widget',
        date: DateTime(2024, 2),
      );
      final otherEntry = buildBonus(
        productName: 'Gadget',
        date: DateTime(2024, 2, 2),
      );

      await notifier.addBonusInfo(widgetEntry);
      await notifier.addBonusInfo(otherEntry);

      final history = notifier.getProductHistory('widget');

      expect(history.length, 1);
      expect(history.first.date, widgetEntry.date);
    });

    test('returns empty history for empty product name', () async {
      final notifier = FakeBonusInfoNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.addBonusInfo(
        buildBonus(productName: 'Widget', date: DateTime(2024, 3)),
      );

      final history = notifier.getProductHistory('   ');

      expect(history, isEmpty);
    });
  });
}
