// add_bonus_info_modal.dart

import 'package:ballistics_wallet_flutter/models/bonus_info_state.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/add_bonus_info_notifier_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';


class AddBonusInfoModal extends ConsumerStatefulWidget {
  const AddBonusInfoModal({super.key});

  @override
  _AddBonusInfoModalState createState() => _AddBonusInfoModalState();
}

class _AddBonusInfoModalState extends ConsumerState<AddBonusInfoModal> {
  final _formKey = GlobalKey<FormState>();

  // Local controllers for the form fields
  List<TextEditingController> productNameControllers = [];
  List<TextEditingController> amountControllers = [];
  TextEditingController bonusController = TextEditingController();
  TextEditingController workingHoursController = TextEditingController();

  // List of FocusNodes for product name fields
  List<FocusNode> productNameFocusNodes = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers based on the notifier's initial state
    final initialProduced = ref.read(addBonusInfoProvider).producedData;
    productNameControllers = List.generate(
      initialProduced.length,
      (index) =>
          TextEditingController(text: initialProduced[index]['productName']),
    );
    amountControllers = List.generate(
      initialProduced.length,
      (index) => TextEditingController(text: initialProduced[index]['amount']),
    );
    productNameFocusNodes = List.generate(
      initialProduced.length,
      (index) => FocusNode(),
    );
    bonusController.text =
        ref.read(addBonusInfoProvider).bonus.toStringAsFixed(2);
    workingHoursController.text =
        ref.read(addBonusInfoProvider).workingHours.toString();
  }

  @override
  void dispose() {
    for (final controller in productNameControllers) {
      controller.dispose();
    }
    for (final controller in amountControllers) {
      controller.dispose();
    }
    for (final focusNode in productNameFocusNodes) {
      focusNode.dispose();
    }
    bonusController.dispose();
    workingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addBonusInfoProvider);
    final notifier = ref.read(addBonusInfoProvider.notifier);
    final productList = ref.watch(productInfoProvider);

    // Listen to state changes to update controllers accordingly
    ref.listen<AddBonusInfoState>(addBonusInfoProvider, (previous, next) {
      if (previous?.bonus != next.bonus) {
        bonusController.text = next.bonus.toStringAsFixed(2);
      }
      if (previous?.workingHours != next.workingHours) {
        workingHoursController.text = next.workingHours.toString();
      }
    });

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Build all product rows
                Column(
                  children: [
                    ...List.generate(
                      state.producedData.length,
                      (index) => Row(
                        children: [
                          // Product Name (TypeAhead)
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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
                                child: TypeAheadField<ProductInfo>(
                                  key: index == 0
                                      ? const Key('productNameField')
                                      : null,

                                  // Provide your own controller and focusNode if desired:
                                  controller: productNameControllers[index],
                                  focusNode: productNameFocusNodes[index],

                                  // How to fetch suggestions:
                                  suggestionsCallback: (pattern) {
                                    final query = pattern.trim().toLowerCase();
                                    return productList
                                        .where(
                                          (p) => p.productName
                                              .toLowerCase()
                                              .contains(query),
                                        )
                                        .toList();
                                  },

                                  // How to build each suggestion in the dropdown:
                                  itemBuilder: (context, suggestion) =>
                                      ListTile(
                                    title: Text(suggestion.productName),
                                  ),

                                  // What to do when a user taps a suggestion:
                                  onSelected: (suggestion) {
                                    productNameControllers[index].text =
                                        suggestion.productName;
                                    notifier.updateProducedData(
                                      index,
                                      'productName',
                                      suggestion.productName,
                                    );
                                    // Move focus or do anything else here:
                                    FocusScope.of(context)
                                        .requestFocus(FocusNode());
                                  },

                                  // (Optional) what to show if no items are found
                                  emptyBuilder: (context) => const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text('No matches found'),
                                  ),

                                  // Build the actual TextField here:
                                  builder:
                                      (context, textController, focusNode) =>
                                          DecoratedBox(
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
                                      controller:
                                          textController, // Use the provided controller
                                      focusNode:
                                          focusNode, // Use the provided focus node
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
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Amount TextField
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.21,
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
                              child: TextFormField(
                                key: const Key('amountField'),
                                controller: amountControllers[index],
                                decoration: InputDecoration(
                                  alignLabelWithHint: true,
                                  hintText: 'Amount',
                                  label: const Center(child: Text('Amount')),
                                  filled: true,
                                  fillColor: Colors.orange[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(33),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  notifier.updateProducedData(
                                    index,
                                    'amount',
                                    value,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Remove button (for additional rows)
                          if (index > 0)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  productNameControllers.removeAt(index);
                                  amountControllers.removeAt(index);
                                });
                                notifier.removeProducedRow(index);
                              },
                            ),
                        ],
                      ),
                    ),
                    // Add more products button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: const BorderRadius.all(
                              Radius.circular(25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                offset: const Offset(-2, 2.5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.orange.withOpacity(0.5),
                                onTap: () {
                                  setState(() {
                                    productNameControllers
                                        .add(TextEditingController());
                                    amountControllers
                                        .add(TextEditingController());
                                  });
                                  notifier.addProducedRow();
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('More Products'),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.add,
                                        color: Colors.black,
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

                    // Bonus TextField (Read-Only)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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
                        child: TextFormField(
                          key: const Key('bonusField'),
                          controller: bonusController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefix: const Text('£'),
                            alignLabelWithHint: true,
                            label: const Center(child: Text('Bonus')),
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
                        ),
                      ),
                    ),

                    // Working Hours TextField
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
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
                        child: TextFormField(
                          key: const Key('workingHoursField'),
                          controller: workingHoursController,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            label: const Text('Working Hours'),
                            filled: true,
                            fillColor: Colors.purple[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(33),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textAlign: TextAlign.center,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter working hours';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            final workingHours = double.tryParse(value) ?? 0.0;
                            notifier.updateWorkingHours(workingHours);
                          },
                        ),
                      ),
                    ),

                    // Overtime Switch
                    Consumer(
                      builder: (context, ref, child) {
                        final isOvertime =
                            ref.watch(addBonusInfoProvider).isOvertime;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Is Overtime'),
                            Switch(
                              value: isOvertime,
                              onChanged: notifier.toggleOvertime,
                            ),
                          ],
                        );
                      },
                    ),

                    // Submit Button
                    ElevatedButton(
                      key: const Key('addBonusButton'),
                      onPressed: state.isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await notifier.saveBonusInfoAndBackup(context);
                              }
                            },
                      child: state.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Add Bonus'),
                    ),

                    // Display error if any
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
