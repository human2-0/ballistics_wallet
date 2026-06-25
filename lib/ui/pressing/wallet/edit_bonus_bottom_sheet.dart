import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';

Future<void> showEditModal(
  BuildContext context,
  WidgetRef ref,
  BonusInfo bonusInfo,
  int index,
) async {
  // Create a mutable copy of bonusInfo for editing
  var editedBonusInfo = bonusInfo.copyWith();
  final productTargets = <String, int>{};

  // Initialize TextEditingControllers with current values
  final workingHoursController = TextEditingController(
    text: editedBonusInfo.workingHours.toString(),
  );
  final bonusController = TextEditingController(
    text: editedBonusInfo.bonus.toString(),
  );
  final controllers =
      editedBonusInfo.produced
          .map(
            (entry) => {
              'productName': TextEditingController(text: entry.productName),
              'amount': TextEditingController(text: entry.amount.toString()),
            },
          )
          .toList();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder:
        (context) => StatefulBuilder(
          builder: (context, setState) {
            final productList = ref.watch(productInfoProvider);
            void initializeProductTargets() {
              for (final product in editedBonusInfo.produced) {
                // Using firstWhereOrNull to safely find the target, with a null check
                final targetInfo = productList.firstWhere(
                  (p) => p.productName == product.productName,
                  orElse:
                      () => ProductInfo(
                        productName: '',
                        imageName: '',
                        target: 0,
                        product: [const Pressing('', 0, 0)],
                      ), // Return null if no matching product found
                );

                // Safely access the target property, defaulting to 0 if targetInfo is null
                productTargets[product.productName] = targetInfo.target;
              }
            }

            void removeProducedItemAt(int index) {
              setState(() {
                controllers[index]['productName']!.dispose();
                controllers[index]['amount']!.dispose();
                controllers.removeAt(index);
                editedBonusInfo.produced.removeAt(index);
              });
            }

            void addProducedRow() {
              setState(() {
                controllers.add({
                  'productName': TextEditingController(),
                  'amount': TextEditingController(),
                });
                editedBonusInfo.produced.add(
                  Produced(productName: '', amount: 0, ratio: 0),
                );
              });
            }

            void updateProducedItemRatios() {
              final updatedProducedList = List<Produced>.from(
                editedBonusInfo.produced,
              );

              for (var i = 0; i < updatedProducedList.length; i++) {
                final productName = controllers[i]['productName']!.text;
                final amount =
                    int.tryParse(controllers[i]['amount']!.text) ?? 0;
                final target = productTargets[productName] ?? 0;
                final ratio = (target > 0) ? amount / target : 0;

                updatedProducedList[i] = updatedProducedList[i].copyWith(
                  amount: amount,
                  ratio: ratio.toDouble(),
                );
              }

              editedBonusInfo = editedBonusInfo.copyWith(
                produced: updatedProducedList,
              );
            }

            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Editing product info',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 32),
                      ...List.generate(
                        editedBonusInfo.produced.length,
                        (index) => Padding(
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
                                        color: Colors.orange.withValues(
                                          alpha: 0.4,
                                        ),
                                        offset: const Offset(-2, 2.5),
                                      ),
                                    ],
                                  ),
                                  child: TypeAheadField<ProductInfo>(
                                    controller:
                                        controllers[index]['productName'],
                                    // 1) Use the textFieldConfiguration to ensure typed text drives the suggestions.
                                    builder:
                                        (context, textController, focusNode) =>
                                            TextField(
                                              key: Key(
                                                'editProductNameField_$index',
                                              ),
                                              controller: textController,
                                              focusNode: focusNode,
                                              decoration: InputDecoration(
                                                alignLabelWithHint: true,
                                                hintText: 'Product Name',
                                                label: const Center(
                                                  child: Text('Product Name'),
                                                ),
                                                filled: true,
                                                fillColor: Colors.orange[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(33),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),

                                    // 2) Filter suggestions based on what's in the controller above.
                                    suggestionsCallback: (pattern) {
                                      final query =
                                          pattern.trim().toLowerCase();
                                      return productList
                                          .where(
                                            (product) => product.productName
                                                .toLowerCase()
                                                .contains(query),
                                          )
                                          .toList();
                                    },

                                    // 3) How each suggestion appears in the dropdown.
                                    itemBuilder:
                                        (context, suggestion) => ListTile(
                                          title: Text(suggestion.productName),
                                        ),

                                    // 4) What happens when the user selects a suggestion.
                                    onSelected: (suggestion) {
                                      // Update the controller so that the chosen product name is displayed.
                                      controllers[index]['productName']!.text =
                                          suggestion.productName;

                                      // Update editedBonusInfo with the chosen product name.
                                      final newProducedList =
                                          List<Produced>.from(
                                            editedBonusInfo.produced,
                                          );
                                      newProducedList[index] =
                                          newProducedList[index].copyWith(
                                            productName: suggestion.productName,
                                          );
                                      // Also store the target if you need it later for ratio computations.
                                      productTargets[suggestion.productName] =
                                          suggestion.target;

                                      setState(() {
                                        editedBonusInfo = editedBonusInfo
                                            .copyWith(
                                              produced: newProducedList,
                                            );
                                      });
                                    },

                                    // 5) Optional: Show a custom widget if no matches are found.
                                    emptyBuilder:
                                        (context) =>
                                            const Text('No matches found'),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.sizeOf(context).width * 0.28,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(33),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(
                                          alpha: 0.4,
                                        ),
                                        offset: const Offset(-2, 2.5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    key: Key('editAmountField_$index'),
                                    controller: controllers[index]['amount'],
                                    decoration: InputDecoration(
                                      alignLabelWithHint: true,
                                      hintText: 'Amount Made',
                                      filled: true,
                                      fillColor: Colors.orange[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(33),
                                        borderSide: BorderSide.none,
                                      ),
                                      labelText: 'Enter Amount',
                                      labelStyle: const TextStyle(fontSize: 18),
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
                                      editedBonusInfo = editedBonusInfo
                                          .copyWith(
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100], // Background color
                              borderRadius: const BorderRadius.all(
                                Radius.circular(25),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  offset: const Offset(-2, 2.5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                25,
                              ), // Matching the outer Container's borderRadius
                              child: Material(
                                color:
                                    Colors
                                        .transparent, // Makes InkWell ripple effect visible
                                child: InkWell(
                                  splashColor: Colors.orange.withValues(
                                    alpha: 0.4,
                                  ), // Ripple effect color
                                  onTap:
                                      addProducedRow, // Your function to add a new row
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('More Products'),
                                      Padding(
                                        padding: EdgeInsets.all(
                                          8,
                                        ), // Padding around the icon
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.black, // Icon color
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                                color: Colors.green.withValues(alpha: 0.4),
                                offset: const Offset(-2, 2.5),
                              ),
                            ],
                          ),
                          child: TextField(
                            key: const Key('editBonusField'),
                            controller: bonusController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              alignLabelWithHint: true,
                              prefixIcon: const Icon(Icons.currency_pound),
                              label: const Text('Bonus'),
                              labelStyle: const TextStyle(fontSize: 18),
                              hintText: 'Bonus',
                              filled: true,
                              fillColor: Colors.green[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(33),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                              editedBonusInfo = editedBonusInfo.copyWith(
                                bonus: newBonus,
                              );
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
                                color: Colors.purple.withValues(alpha: 0.4),
                                offset: const Offset(-2, 2.5),
                              ),
                            ],
                          ),
                          child: TextField(
                            key: const Key('editWorkingHoursField'),
                            textAlign: TextAlign.center,
                            controller: workingHoursController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.timer_outlined),
                              alignLabelWithHint: true,
                              label: const Text('Working Hours'),
                              labelStyle: const TextStyle(fontSize: 18),
                              filled: true,
                              fillColor: Colors.purple[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(33),
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
                          initializeProductTargets();
                          updateProducedItemRatios();
                          await ref
                              .read(bonusInfoListProvider.notifier)
                              .updateBonusInfo(editedBonusInfo);
                          WidgetsBinding.instance.addPostFrameCallback((
                            timeStamp,
                          ) {
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
        ),
  ).whenComplete(() {
    workingHoursController.dispose();
    bonusController.dispose();
    for (final rowControllers in controllers) {
      rowControllers['productName']!.dispose();
      rowControllers['amount']!.dispose();
    }
  });
}
