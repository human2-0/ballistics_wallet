import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/new_wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> showEditModal(
    BuildContext context,
    WidgetRef ref,
    BonusInfo bonusInfo,
    int index,
    ) async {
  // Create a mutable copy of bonusInfo for editing
  var editedBonusInfo = bonusInfo.copyWith();

  // Initialize TextEditingControllers with current values
  final workingHoursController =
  TextEditingController(text: editedBonusInfo.workingHours.toString());
  final bonusController =
  TextEditingController(text: editedBonusInfo.bonus.toString());

  // Create a List<TextEditingController> for managing the inputs of each 'Produced' amount
  final controllers = editedBonusInfo.produced
      .map((e) => TextEditingController(text: e.amount.toString()))
      .toList();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: workingHoursController,
                  decoration: const InputDecoration(labelText: 'Working hours'),
                  onChanged: (value) {
                    final newWorkingHours = double.tryParse(value) ?? 0.0;
                    editedBonusInfo =
                        editedBonusInfo.copyWith(workingHours: newWorkingHours);
                  },
                ),
                TextField(
                  controller: bonusController,
                  decoration: const InputDecoration(labelText: 'Bonus'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newBonus = double.tryParse(value) ?? 0.0;
                    editedBonusInfo = editedBonusInfo.copyWith(bonus: newBonus);
                  },
                ),
                ...List.generate(editedBonusInfo.produced.length, (index) {
                  return TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      labelText:
                      '${editedBonusInfo.produced[index].productName} - amount made',
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final newAmount = double.tryParse(value) ?? 0.0;
                      final updatedProducedList =
                      List<Produced>.from(bonusInfo.produced);
                      updatedProducedList[index] = updatedProducedList[index]
                          .copyWith(amount: newAmount.toInt());
                      bonusInfo.copyWith(produced: updatedProducedList);
                    },
                  );
                }),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    await ref
                        .read(bonusInfoListProvider.notifier)
                        .updateBonusInfo(editedBonusInfo);
                    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                      context.pop();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
