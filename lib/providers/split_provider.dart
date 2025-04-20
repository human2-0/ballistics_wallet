import 'package:ballistics_wallet_flutter/models/split_calculator_model.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final requiredAmountProvider = StateProvider<int>((ref) => 0);
final amountPerBatchProvider = StateProvider<int>((ref) => 0);

final splitCalculatorProvider = Provider<SplitCalculator>((ref) {
  final requiredAmount = ref.watch(requiredAmountProvider);
  final perBatch = ref.watch(amountPerBatchProvider);
  final workingHours =
      ref.watch(userNotifierProvider.select((u) => u.workingHours)) ?? 0.0;
  return SplitCalculator(requiredAmount, perBatch, workingHours);
});
