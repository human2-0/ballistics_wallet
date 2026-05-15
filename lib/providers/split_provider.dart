import 'package:ballistics_wallet_flutter/models/split_calculator_model.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final requiredAmountProvider = StateProvider<int>((ref) => 0);
final amountPerBatchProvider = StateProvider<int>((ref) => 0);
final perColorOverridesProvider = StateProvider<Map<String, int>>((ref) => {});

const _splitCheckColorsBox = 'split_check_colors';
const _splitCheckColorsKey = 'perColorDisplayOverrides';

class PerColorDisplayOverridesNotifier
    extends StateNotifier<Map<String, String>> {
  PerColorDisplayOverridesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_splitCheckColorsBox);
    final stored = box.get(_splitCheckColorsKey);
    if (stored is Map) {
      final casted = <String, String>{};
      stored.forEach((key, value) {
        if (key is String && value is String) {
          casted[key] = value;
        }
      });
      state = casted;
    }
  }

  Future<void> _save() async {
    final box = await Hive.openBox(_splitCheckColorsBox);
    await box.put(_splitCheckColorsKey, state);
  }

  void setOverride(String key, String value) {
    state = {...state, key: value};
    _save();
  }

  void clearOverride(String key) {
    final next = {...state};
    next.remove(key);
    state = next;
    _save();
  }

  void reset() {
    state = {};
    _save();
  }
}

final perColorDisplayOverridesProvider =
    StateNotifierProvider<PerColorDisplayOverridesNotifier, Map<String, String>>(
  (ref) => PerColorDisplayOverridesNotifier(),
);

final splitCalculatorProvider = Provider<SplitCalculator>((ref) {
  final requiredAmount = ref.watch(requiredAmountProvider);
  final perBatch = ref.watch(amountPerBatchProvider);
  final workingHours =
      ref.watch(userNotifierProvider.select((u) => u.workingHours)) ?? 0.0;
  return SplitCalculator(requiredAmount, perBatch, workingHours);
});
