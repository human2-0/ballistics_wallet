import 'dart:io';

import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late UserRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }
    repo = UserRepository();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteBoxFromDisk('settings');
    await tempDir.delete(recursive: true);
  });

  test('saveOrUpdateUserData and getUserData store and retrieve user', () async {
    final user = UserSettings(userId: 'user1');
    await repo.saveOrUpdateUserData(user);

    final fetched = await repo.getUserData('user1');
    expect(fetched?.userId, 'user1');
  });

  test('editWorkingHours updates working hours with effective value', () async {
    final user = UserSettings(userId: 'user2');
    await repo.saveOrUpdateUserData(user);

    final success = await repo.editWorkingHours('user2', 8);
    final updated = await repo.getUserData('user2');
    expect(success, true);
    expect(updated?.workingHours, 7.0);
    expect(updated?.realWorkingHours, 8.0);
  });

  test('editPaidBreaks and editHourlyRate update user fields', () async {
    final user = UserSettings(userId: 'user3');
    await repo.saveOrUpdateUserData(user);

    await repo.editPaidBreaks('user3', true);
    await repo.editHourlyRate('user3', 20);

    final updated = await repo.getUserData('user3');
    expect(updated?.paidBreaks, true);
    expect(updated?.hourlyRate, 20.0);
  });

  test('calculateEffectiveWorkingHours returns expected values', () {
    expect(repo.calculateEffectiveWorkingHours(8), 7.0);
    expect(repo.calculateEffectiveWorkingHours(6), 5.5);
    expect(repo.calculateEffectiveWorkingHours(4), 3.75);
    expect(repo.calculateEffectiveWorkingHours(5), 5.0);
  });
}
