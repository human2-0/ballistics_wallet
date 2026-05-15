import 'dart:io';

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/repository/bonus_info_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive..init(tempDir.path)
    ..registerAdapter(BonusInfoAdapter())
    ..registerAdapter(ProducedAdapter());
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('bonusInfoBox');
    await tempDir.delete(recursive: true);
  });

  test('addBonusInfo updates existing entry for same day', () async {
    final repo = BonusInfoRepository();
    final box = await repo.openBox();
    final date = DateTime(2024);

    final existing = BonusInfo(
      userId: 'user1',
      bonus: 0,
      date: date,
      workingHours: 8,
      isOvertime: false,
      produced: [Produced(productName: 'Widget', amount: 10, ratio: 0)],
    );
    await box.put(existing.id, existing);

    final updated = BonusInfo(
      userId: 'user1',
      bonus: 0,
      date: date,
      workingHours: 8,
      isOvertime: false,
      produced: [Produced(productName: 'Widget', amount: 20, ratio: 0)],
    );

    final message = await repo.addBonusInfo(updated);

    final result = box.get(existing.id);
    expect(message, 'Product updated successfully.');
    expect(result?.produced.first.amount, 20);
  });
}
