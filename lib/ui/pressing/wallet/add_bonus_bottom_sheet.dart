import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';

class AddBonusInfoModal extends ConsumerStatefulWidget {
  const AddBonusInfoModal({required this.context, super.key});
  final BuildContext context;

  @override
  _AddBonusInfoModalState createState() => _AddBonusInfoModalState();
}

class _AddBonusInfoModalState extends ConsumerState<AddBonusInfoModal> {
  List<Map<String, TextEditingController>> producedControllers = [];
  Map<String, int> productTargets = {};
  final bonusController = TextEditingController();

  late double ratio = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with one set of controllers
    producedControllers.add({
      'productName': TextEditingController(),
      'amount': TextEditingController(),
    });
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    for (final controllers in producedControllers) {
      controllers['productName']!.dispose();
      controllers['amount']!.dispose();
    }
    super.dispose();
  }

  void addProducedRow() {
    setState(() {
      producedControllers.add({
        'productName': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  List<Produced> handleSubmit() {
    final producedItems = producedControllers.map((controllers) {
      final productName = controllers['productName']!.text;
      final amount = int.tryParse(controllers['amount']!.text) ?? 0;
      final target = productTargets[productName] ?? 0;
      final ratio = amount != 0 && target != 0
          ? amount / target
          : 0; // Calculate the ratio

      return Produced(
        productName: productName,
        amount: amount,
        ratio: ratio.toDouble(), // Store the calculated ratio
      );
    }).toList();

    // Optionally, clear the productTargets map if you're done with it
    productTargets.clear();

    return producedItems;
  }

  void updateBonus() {
    var sumOfRatios = 0.0;
    for (final controllers in producedControllers) {
      final productName = controllers['productName']!.text;
      final amount = int.tryParse(controllers['amount']!.text) ?? 0;
      final target = productTargets[productName] ?? 0;
      final ratio = amount != 0 && target != 0 ? amount / target : 0;

      sumOfRatios += ratio;
    }

    final bonusValue = ref.read(bonusCalculator(sumOfRatios));
    bonusController.text =
        bonusValue.toStringAsFixed(2); // Update bonusController
  }

  @override
  Widget build(BuildContext context) {
    final productList = ref.watch(productInfoProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final userState = ref.watch(userNotifierProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final userId = authRepository.currentUserId;

    final workingHoursController =
        TextEditingController(text: userState.realWorkingHours!.toString());

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(producedControllers.length, (index) => Row(
                  children: [
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
                          child: TypeAheadFormField<ProductInfo>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: producedControllers[index]
                                  ['productName'],
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
                              ),
                              textAlign: TextAlign.center,
                            ),
                            suggestionsCallback: (pattern) {
                              // Assuming productList is a List<Product>
                              // Filter or process your list based on the pattern if needed
                              return productList.where(
                                (product) => product.productName
                                    .toLowerCase()
                                    .contains(pattern.toLowerCase()),
                              );
                            },
                            itemBuilder: (context, suggestion) {
                              // suggestion is now a Product object
                              return ListTile(
                                title: Text(suggestion.productName),
                              );
                            },
                            onSuggestionSelected: (suggestion) {
                              producedControllers[index]['productName']!.text =
                                  suggestion.productName;
                              productTargets[suggestion.productName] =
                                  suggestion.target; // Store the target
                            },
                            noItemsFoundBuilder: (context) =>
                                const Text('No matches found'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                        child: TextField(
                          controller: producedControllers[index]['amount'],
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
                          onChanged: (value) {
                            updateBonus();
                          },
                        ),
                      ),
                    ),
                    if (index > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            // Prevent removal if only one controller set remains
                            if (producedControllers.length > 1) {
                              producedControllers.removeAt(index);
                            }
                          });
                        },
                      ),
                  ],
                ),),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100], // Background color
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.5),
                          offset: const Offset(-2, 2.5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        25,
                      ), // Matching the outer Container's borderRadius
                      child: Material(
                        color: Colors
                            .transparent, // Makes InkWell ripple effect visible
                        child: InkWell(
                          splashColor: Colors.orange
                              .withOpacity(0.5), // Ripple effect color
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
                  child: TextField(
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
                        borderRadius: BorderRadius.circular(
                          33,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                  ),
                ),
              ),
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
                  child: TextField(
                    controller: workingHoursController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      alignLabelWithHint: true,
                      label: const Text('Working Hours'),
                      filled: true,
                      fillColor: Colors.purple[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          33,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                  ),
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isOvertime = ref.watch(
                    isOvertimeProvider,
                  ); // Listen to the isOvertimeProvider

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Is Overtime'),
                      Switch(
                        value:
                            isOvertime, // Use the provider's state as the value
                        onChanged: (value) {
                          // Update the provider's state when the switch is toggled
                          ref.read(isOvertimeProvider.notifier).state = value;
                        },
                      ),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  final producedItems = handleSubmit();
                  final newBonusInfo = BonusInfo(
                    userId: userId,
                    bonus: double.tryParse(bonusController.text) ?? 0,
                    date: selectedDate,
                    workingHours:
                        double.tryParse(workingHoursController.text) ?? 0,
                    isOvertime: ref.read(isOvertimeProvider),
                    produced:
                        producedItems, // Initialize with empty or collect data as needed
                  );
                  await ref
                      .read(bonusInfoListProvider.notifier)
                      .addBonusInfo(newBonusInfo);
                  await ref.read(backupManagerProvider.notifier).backupData();
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    context.pop();

                  });
                },
                child: const Text('Add Bonus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
