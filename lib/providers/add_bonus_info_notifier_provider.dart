import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/bonus_info_state.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddBonusInfoNotifier extends StateNotifier<AddBonusInfoState> {
  AddBonusInfoNotifier(this.ref)
    : super(
        AddBonusInfoState(
          producedData: [
            {'productName': '', 'amount': ''},
          ],
        ),
      ) {
    initialize();
  }

  final Ref ref;

  // Initialize the working hours based on user settings
  void initialize() {
    final userState = ref.read(userNotifierProvider);
    state = state.copyWith(workingHours: userState.realWorkingHours ?? 0.0);
  }

  // Add a new produced row
  void addProducedRow() {
    final updatedProduced = [
      ...state.producedData,
      {'productName': '', 'amount': ''},
    ];
    state = state.copyWith(producedData: updatedProduced);
  }

  // Remove a produced row at a specific index
  void removeProducedRow(int index) {
    if (index < 0 || index >= state.producedData.length) return;
    final updatedProduced = List<Map<String, String>>.from(state.producedData)
      ..removeAt(index);
    state = state.copyWith(producedData: updatedProduced);
    computeBonus(); // Recompute bonus after removal
  }

  // Update produced data at a specific index
  void updateProducedData(int index, String key, String value) {
    if (index < 0 || index >= state.producedData.length) return;
    final updatedProduced = List<Map<String, String>>.from(state.producedData);
    final updatedRow = Map<String, String>.from(updatedProduced[index]);
    updatedRow[key] = value;
    updatedProduced[index] = updatedRow;
    state = state.copyWith(producedData: updatedProduced);
    computeBonus(); // Recompute bonus whenever data changes
  }

  // Toggle overtime status
  void toggleOvertime(bool value) {
    state = state.copyWith(isOvertime: value);
    computeBonus();
  }

  // Update working hours
  void updateWorkingHours(double workingHours) {
    state = state.copyWith(workingHours: workingHours);
    computeBonus();
  }

  // Compute the bonus based on the produced data and overtime
  void computeBonus() {
    var sumOfRatios = 0.0;
    for (final row in state.producedData) {
      final productName = row['productName'] ?? '';
      final amountStr = row['amount'] ?? '';
      final amount = double.tryParse(amountStr) ?? 0.0;
      final productList = ref.read(productInfoProvider);
      final product = productList.firstWhere(
        (p) => p.productName == productName,
        orElse:
            () => ProductInfo(
              productName: productName,
              imageName: '',
              target: 0,
              product: [],
            ),
      );
      final target = product.target;
      final ratio = (amount != 0 && target != 0) ? amount / target : 0.0;
      sumOfRatios += ratio;
    }

    // Assuming bonusCalculator is a provider that takes sumOfRatios and returns bonus
    final bonusValue = ref.read(bonusCalculator(sumOfRatios));
    state = state.copyWith(bonus: bonusValue);
  }

  // Handle form submission
  Future<void> saveBonusInfoAndBackup(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      final producedItems = handleSubmit();
      final userState = ref.read(userNotifierProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final userId = authRepository.currentUserId;
      final selectedDate = ref.read(selectedDateProvider);

      final newBonusInfo = BonusInfo(
        userId: userId,
        bonus: state.bonus,
        date: selectedDate,
        workingHours: state.workingHours,
        isOvertime: state.isOvertime,
        produced: producedItems,
      );

      await ref.read(bonusInfoListProvider.notifier).addBonusInfo(newBonusInfo);

      // Close the modal using GoRouter's navigation
      if (context.mounted) {
        context.pop();
      }

      // Backup data in the background, if enabled
      if (userState.backup!) {
        Future.delayed(Duration.zero, () async {
          await ref.read(backupManagerProvider.notifier).backupData();
        });
      }

      state = state.copyWith(isLoading: false);
    } on FormatException catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Convert produced data into a list of Produced objects
  List<Produced> handleSubmit() {
    final producedItems =
        state.producedData.map((row) {
          final productName = row['productName'] ?? '';
          final amount = double.tryParse(row['amount'] ?? '') ?? 0.0;
          final productList = ref.read(productInfoProvider);
          final product = productList.firstWhere(
            (p) => p.productName == productName,
            orElse:
                () => ProductInfo(
                  productName: productName,
                  imageName: '',
                  target: 0,
                  product: [],
                ),
          );
          final target = product.target;
          final ratio = (amount != 0 && target != 0) ? amount / target : 0.0;

          return Produced(
            productName: productName,
            amount: amount.toInt(),
            ratio: ratio,
          );
        }).toList();

    return producedItems;
  }
}

// Define the provider
final addBonusInfoProvider =
    StateNotifierProvider<AddBonusInfoNotifier, AddBonusInfoState>(
      AddBonusInfoNotifier.new,
    );
