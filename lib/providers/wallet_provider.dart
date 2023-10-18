

import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/wallet_repository.dart';
import '../repository/target_check_repository.dart';

final userBonusNotifierProvider =
StateNotifierProvider<UserBonusNotifier, Map<DateTime, List<dynamic>>>(
        (ref) {
      final repository = ref.watch(pressingRepositoryProvider);
      return UserBonusNotifier(repository);
    });


final bonusTableSelectorProvider =
StateNotifierProvider<BonusTableSelector, bool>((ref) {
  return BonusTableSelector();
});

final bonusAmountControllerProvider =
StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
      (ref) => TextFieldStateNotifier(''),
);

final productNameControllerProvider =
StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
      (ref) => TextFieldStateNotifier(''),
);

final productAmountControllerProvider =
StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
      (ref) => TextFieldStateNotifier(''),
);

final overtimeHoursControllerProvider =
StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
      (ref) => TextFieldStateNotifier(''),
);

final monthlyBonusProvider = Provider<int>((ref) {
  final userBonusesNotifier = ref.watch(userBonusesProvider.notifier);
  return userBonusesNotifier.calculateMonthlyBonus();
});

final ratioCalendar = StateProvider<double>((ref){
  return 0.0;
});


