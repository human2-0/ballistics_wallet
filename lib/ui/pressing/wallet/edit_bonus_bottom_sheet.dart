import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final localProducedItems = List<Produced>.from(editedBonusInfo.produced);
      final controllers = localProducedItems
          .map((e) => TextEditingController(text: e.amount.toString()))
          .toList();

      return StatefulBuilder(
        builder: (context, setState) {
          void removeProducedItemAt(int index) {
            setState(() {
              localProducedItems.removeAt(index);
              controllers[index].dispose();
              controllers.removeAt(index);
              final updatedProducedList =
                  List<Produced>.from(editedBonusInfo.produced)
                    ..removeAt(index);
              editedBonusInfo = editedBonusInfo.copyWith(
                produced: updatedProducedList,
              );
            });
          }

          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SingleChildScrollView(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Editing product info',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    ...List.generate(editedBonusInfo.produced.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(33),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.5),
                                      offset: const Offset(-2, 2.5),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: controllers[index],
                                  decoration: InputDecoration(
                                    alignLabelWithHint: true,
                                    hintText: 'Product Name',
                                    filled: true,
                                    fillColor: Colors.orange[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        33,
                                      ),
                                      borderSide: BorderSide.none,
                                    ),
                                    labelText:
                                        '${editedBonusInfo.produced[index].productName} - amount made',
                                    labelStyle: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  textAlign: TextAlign.center,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (value) {
                                    final newAmount =
                                        double.tryParse(value) ?? 0.0;
                                    final updatedProducedList =
                                        List<Produced>.from(
                                      editedBonusInfo.produced,
                                    );
                                    updatedProducedList[index] =
                                        updatedProducedList[index].copyWith(
                                      amount: newAmount.toInt(),
                                    );
                                    editedBonusInfo = editedBonusInfo.copyWith(
                                      produced: updatedProducedList,
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (editedBonusInfo.produced.length > 1)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => removeProducedItemAt(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              offset: const Offset(-2, 2.5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: bonusController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(Icons.currency_pound),
                            label: const Text('Bonus'),
                            labelStyle: const TextStyle(
                              fontSize: 18,
                            ),
                            hintText: 'Bonus',
                            filled: true,
                            fillColor: Colors.green[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                33,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp('[0-9]+[,.]{0,1}[0-9]*'),
                            ),
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.replaceAll(',', '.'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            final newBonus = double.tryParse(value) ?? 0.0;
                            editedBonusInfo =
                                editedBonusInfo.copyWith(bonus: newBonus);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.5),
                              offset: const Offset(-2, 2.5),
                            ),
                          ],
                        ),
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: workingHoursController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.timer_outlined,
                            ),
                            alignLabelWithHint: true,
                            label: const Text('Working Hours'),
                            labelStyle: const TextStyle(
                              fontSize: 18,
                            ),
                            filled: true,
                            fillColor: Colors.purple[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                33,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            final newWorkingHours =
                                double.tryParse(value) ?? 0.0;
                            editedBonusInfo = editedBonusInfo.copyWith(
                              workingHours: newWorkingHours,
                            );
                          },
                        ),
                      ),
                    ),
                    ElevatedButton(
                      child: const Text('Save'),
                      onPressed: () async {
                        await ref
                            .read(bonusInfoListProvider.notifier)
                            .updateBonusInfo(editedBonusInfo);
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
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
    },
  );
}
