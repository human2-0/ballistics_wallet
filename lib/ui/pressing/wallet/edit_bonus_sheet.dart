import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class EditBonusInfoModal extends ConsumerStatefulWidget {
  const EditBonusInfoModal({
    required this.bonusInfo,
    required this.index,
    super.key,
  });
  final BonusInfo bonusInfo;
  final int index;

  @override
  _EditBonusInfoModalState createState() => _EditBonusInfoModalState();
}

class _EditBonusInfoModalState extends ConsumerState<EditBonusInfoModal> {
  final _formKey = GlobalKey<FormState>();

  late BonusInfo editedBonusInfo;
  final Map<String, int> productTargets = {};

  // Controllers for produced items.
  late List<TextEditingController> productNameControllers;
  late List<TextEditingController> amountControllers;

  // We'll keep a map to capture the text controllers that the builder provides.

  // Controllers for bonus and working hours fields.
  late TextEditingController bonusController;
  late TextEditingController workingHoursController;

  late List<FocusNode> productNameFocusNodes;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the bonus info.
    editedBonusInfo = widget.bonusInfo.copyWith();

    // Create controllers for each produced item (used elsewhere if needed).
    productNameControllers = editedBonusInfo.produced
        .map((p) => TextEditingController(text: p.productName))
        .toList();
    amountControllers = editedBonusInfo.produced
        .map((p) => TextEditingController(text: p.amount.toString()))
        .toList();
    productNameFocusNodes =
        editedBonusInfo.produced.map((_) => FocusNode()).toList();

    bonusController =
        TextEditingController(text: editedBonusInfo.bonus.toStringAsFixed(2));
    workingHoursController =
        TextEditingController(text: editedBonusInfo.workingHours.toString());
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

  /// Initializes [productTargets] using the provided [productList].
  void initializeProductTargets(List<ProductInfo> productList) {
    for (final product in editedBonusInfo.produced) {
      final targetInfo = productList.firstWhere(
        (p) => p.productName == product.productName,
        orElse: () => ProductInfo(
          productName: '',
          imageName: '',
          target: 0,
          product: [const Pressing('', 0, 0)],
        ),
      );
      productTargets[product.productName] = targetInfo.target;
    }
  }

  /// Update the ratio and amount values for each produced product.
  void updateProducedItemRatios() {
    final updatedProducedList = List<Produced>.from(editedBonusInfo.produced);
    for (var i = 0; i < updatedProducedList.length; i++) {
      final productName = productNameControllers[i].text;
      final amount = int.tryParse(amountControllers[i].text) ?? 0;
      final target = productTargets[productName] ?? 0;
      final ratio = (target > 0) ? amount / target : 0.0;
      updatedProducedList[i] = updatedProducedList[i].copyWith(
        productName: productName,
        amount: amount,
        ratio: ratio,
      );
    }
    editedBonusInfo = editedBonusInfo.copyWith(produced: updatedProducedList);
  }

  void addProducedRow() {
    setState(() {
      productNameControllers.add(TextEditingController());
      amountControllers.add(TextEditingController());
      productNameFocusNodes.add(FocusNode());
      editedBonusInfo.produced
          .add(Produced(productName: '', amount: 0, ratio: 0));
    });
  }

  void removeProducedRow(int index) {
    if (editedBonusInfo.produced.length > 1) {
      setState(() {
        productNameControllers[index].dispose();
        amountControllers[index].dispose();
        productNameFocusNodes[index].dispose();
        productNameControllers.removeAt(index);
        amountControllers.removeAt(index);
        productNameFocusNodes.removeAt(index);
        editedBonusInfo.produced.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productList = ref.watch(productInfoProvider);
    // Update product targets.
    initializeProductTargets(productList);

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
                const Text(
                  'Editing Bonus Info',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                // Produced items list.
                ...List.generate(
                  editedBonusInfo.produced.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(33),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  offset: const Offset(-2, 2.5),
                                ),
                              ],
                            ),
                            child: TypeAheadField<ProductInfo>(
                              // Using the builder parameter
                              builder: (context, textController, focusNode) {
                                // Capture the textController in our map so we can use it in onSelected.
                                textController.text =
                                    productNameControllers[index].text;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(33),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(alpha: 0.4),
                                        offset: const Offset(-2, 2.5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    key: Key('editProductNameField_$index'),
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
                                        borderRadius: BorderRadius.circular(33),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                    onChanged: (value) {
                                      // Update the corresponding controller so that your data model is updated.
                                      productNameControllers[index].text =
                                          value;
                                    },
                                  ),
                                );
                              },

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
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text(suggestion.productName),
                                );
                              },
                              onSelected: (suggestion) {
                                setState(() {
                                  // Use the captured textController from our map.
                                  // Also update the controller in our list for consistency.
                                  productNameControllers[index].text =
                                      suggestion.productName;
                                  editedBonusInfo.produced[index] =
                                      editedBonusInfo.produced[index].copyWith(
                                    productName: suggestion.productName,
                                  );
                                });
                                productTargets[suggestion.productName] =
                                    suggestion.target;
                                // Optionally, unfocus the field.
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                              },
                              emptyBuilder: (context) => const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('No matches found'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(33),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.4),
                                offset: const Offset(-2, 2.5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            key: Key('editAmountField_$index'),
                            controller: amountControllers[index],
                            decoration: InputDecoration(
                              hintText: 'Amount Made',
                              labelText: 'Enter Amount',
                              filled: true,
                              fillColor: Colors.orange[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(33),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
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
                              final newAmount = int.tryParse(value) ?? 0;
                              setState(() {
                                editedBonusInfo.produced[index] =
                                    editedBonusInfo.produced[index]
                                        .copyWith(amount: newAmount);
                              });
                            },
                          ),
                        ),
                        if (editedBonusInfo.produced.length > 1)
                          IconButton(
                            key: Key('removeProducedRow_$index'),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => removeProducedRow(index),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: InkWell(
                      onTap: addProducedRow,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('More Products'),
                          SizedBox(width: 8),
                          Icon(Icons.add, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bonus field.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    key: const Key('editBonusField'),
                    controller: bonusController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.currency_pound),
                      hintText: 'Bonus',
                      label: const Text('Bonus'),
                      filled: true,
                      fillColor: Colors.green[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(33),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
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
                      setState(() {
                        editedBonusInfo =
                            editedBonusInfo.copyWith(bonus: newBonus);
                      });
                    },
                  ),
                ),
                // Working hours field.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextFormField(
                    key: const Key('editWorkingHoursField'),
                    controller: workingHoursController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.timer_outlined),
                      hintText: 'Working Hours',
                      label: const Text('Working Hours'),
                      filled: true,
                      fillColor: Colors.purple[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(33),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
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
                      final newWorkingHours = double.tryParse(value) ?? 0.0;
                      setState(() {
                        editedBonusInfo = editedBonusInfo.copyWith(
                          workingHours: newWorkingHours,
                        );
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  key: const Key('saveEditButton'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      updateProducedItemRatios();
                      await ref
                          .read(bonusInfoListProvider.notifier)
                          .updateBonusInfo(editedBonusInfo);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
