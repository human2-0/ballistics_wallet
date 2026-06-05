import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class UserRepository {
  static const String _boxName = 'settings';

  Future<Box<UserSettings>> _openBox() => Hive.openBox<UserSettings>(_boxName);

  Future<UserSettings?> getUserData(String userId) async {
    final box = await _openBox();
    return box.get(userId);
  }

  Future<void> saveOrUpdateUserData(UserSettings user) async {
    final box = await _openBox();
    await box.put(user.userId, user);
  }

  Future<bool> editWorkingHours(String userId, double newWorkingHours) async {
    final box = await _openBox();
    final user = box.get(userId);
    if (user == null) return false;

    final updatedUser = user.copyWith(
      workingHours: calculateEffectiveWorkingHours(newWorkingHours),
      realWorkingHours: newWorkingHours,
    );
    await box.put(userId, updatedUser);
    return true;
  }

  Future<bool> editPaidBreaks(String userId, bool newPaidBreaks) async {
    final box = await _openBox();
    final user = box.get(userId);
    if (user == null) return false;

    final updatedUser = user.copyWith(paidBreaks: newPaidBreaks);
    await box.put(userId, updatedUser);
    return true;
  }

  Future<bool> editHourlyRate(String userId, double newHourlyRate) async {
    final box = await _openBox();
    final user = box.get(userId);
    if (user == null) return false;

    final updatedUser = user.copyWith(hourlyRate: newHourlyRate);
    await box.put(userId, updatedUser);
    return true;
  }

  double calculateEffectiveWorkingHours(double workingHours) {
    if (workingHours == 8.0) {
      return workingHours - 1.0;
    } else if (workingHours == 4.0) {
      return workingHours - 0.25;
    } else if (workingHours == 6.0) {
      return workingHours - 0.5;
    } else {
      return workingHours;
    }
  }
}

class UserState {
  UserState({
    this.userId,
    this.workingHours,
    this.realWorkingHours,
    this.avatarUrl,
    this.paidBreaks,
    this.hourlyRate,
    this.backup,
    this.askForBackup,
  });
  final String? userId;
  final double? workingHours;
  final double? realWorkingHours;
  final String? avatarUrl;
  final bool? paidBreaks;
  final double? hourlyRate;
  final bool? backup;
  final bool? askForBackup;

  UserState copyWith({
    String? userId,
    double? workingHours,
    double? realWorkingHours,
    String? avatarUrl,
    bool? paidBreaks,
    double? hourlyRate,
    bool? backup,
    bool? askForBackup,
  }) => UserState(
    userId: userId ?? this.userId,
    workingHours: workingHours ?? this.workingHours,
    realWorkingHours: realWorkingHours ?? this.realWorkingHours,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    paidBreaks: paidBreaks ?? this.paidBreaks,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    backup: backup ?? this.backup,
    askForBackup: askForBackup ?? this.askForBackup,
  );
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this.userRepository) : super(UserState());
  final UserRepository userRepository;

  double calculateEffectiveWorkingHours(double workingHours) =>
      userRepository.calculateEffectiveWorkingHours(workingHours);

  Future<void> dontAskAgain(bool value) async {
    state = state.copyWith(askForBackup: value);
    await _saveSettings();
  }

  Future<void> doBackUp(bool value) async {
    state = state.copyWith(backup: value);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final settings = UserSettings(
      userId: state.userId!,
      workingHours: state.workingHours,
      realWorkingHours: state.realWorkingHours,
      avatarUrl: state.avatarUrl,
      paidBreaks: state.paidBreaks,
      hourlyRate: state.hourlyRate,
      backup: state.backup,
      askForBackup: state.askForBackup,
    );
    await userRepository.saveOrUpdateUserData(settings);
  }

  Future<void> loadUser(String userId) async {
    final userSettings = await userRepository.getUserData(userId);
    if (userSettings != null) {
      state = UserState(
        userId: userSettings.userId,
        workingHours: userSettings.workingHours,
        realWorkingHours: userSettings.realWorkingHours,
        avatarUrl: userSettings.avatarUrl,
        paidBreaks: userSettings.paidBreaks,
        hourlyRate: userSettings.hourlyRate,
        backup: userSettings.backup,
        askForBackup: userSettings.askForBackup,
      );
    }
  }

  Future<bool> updateUserSettings(
    double newWorkingHours,
    double newHourlyRate,
  ) async {
    if (state.userId == null) return false;

    final updateWorkingHoursResult = await userRepository.editWorkingHours(
      state.userId!,
      newWorkingHours,
    );
    final updateHourlyRateResult = await userRepository.editHourlyRate(
      state.userId!,
      newHourlyRate,
    );

    if (updateWorkingHoursResult && updateHourlyRateResult) {
      state = state.copyWith(
        workingHours: calculateEffectiveWorkingHours(newWorkingHours),
        realWorkingHours: newWorkingHours,
        hourlyRate: newHourlyRate,
      );
      await _saveSettings();
      return true;
    }

    return false;
  }

  Future<bool> editPaidBreaks(bool newPaidBreaks) async {
    if (state.userId == null) return false;
    final result = await userRepository.editPaidBreaks(
      state.userId!,
      newPaidBreaks,
    );
    if (result) {
      state = state.copyWith(paidBreaks: newPaidBreaks);
    }
    return result;
  }

  Future<void> updateUser(UserState user) async {
    state = state.copyWith(
      userId: user.userId ?? state.userId,
      workingHours: user.workingHours ?? state.workingHours,
      realWorkingHours: user.realWorkingHours ?? state.realWorkingHours,
      avatarUrl: user.avatarUrl ?? state.avatarUrl,
      paidBreaks: user.paidBreaks ?? state.paidBreaks,
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(),
);

final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref.watch(userRepositoryProvider)),
);

final userDataProvider = FutureProvider.family<UserSettings?, String>((
  ref,
  uid,
) {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getUserData(uid);
});
