import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Dialog function
Future<void> showEditProductDialog(
  BuildContext context,
  WidgetRef ref, {
  required ProductInfo product,
}) async {
  // Initialize the TextEditingControllers with the current product info
  var custom = false;
  var ayr = product.ayr ?? false;

  // Convert each Pressing into a PressingEntry for editing
  final pressingEntries =
      product.product.map(PressingEntry.fromPressing).toList();

  void addPressingEntry(StateSetter setState) {
    setState(() {
      pressingEntries.add(PressingEntry());
    });
  }

  var selectedRatio = 3.0; // Example initial ratio value
  var ratioTextFieldValue = '3.0'; // To keep the TextField in sync


  final productNameController =
  TextEditingController(text: product.productName);
  final targetController =
  TextEditingController(text: product.target.toString());



  await showDialog<Widget>(
    context: context,
    builder: (context) => Dialog(
      child: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Edit product',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CustomTextField(
                    controller: productNameController,
                    hintText: 'Product Name',
                    labelText: 'Product Name',
                    enabled: false,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CustomTextField(
                    controller: targetController,
                    hintText: 'Target',
                    labelText: 'Target',
                    keyboardType: TextInputType.number,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('All year round'),
                      Checkbox(
                        value: ayr,
                        onChanged: (value) {
                          setState(() {
                            ayr = value ?? false;
                            if (ayr) {
                             product.copyWith(ayr: ayr);
                              }
                          });
                        },
                      ),
                    ],
                  ),
                  if (pressingEntries.isNotEmpty)
                    const SizedBox(
                      height: 16,
                    ),
                  if (pressingEntries.isNotEmpty)
                    const Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                  if (pressingEntries.isNotEmpty)
                    const SizedBox(
                      height: 16,
                    ),
                  if (pressingEntries.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow[100]!.withValues(alpha: 0.8),
                            offset: const Offset(4, -2.5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: Colors.yellow[500]!.withValues(alpha: 0.8),
                        leading: const Icon(Icons.info_outline_rounded),
                        title: Text(
                          'Ratio: ${selectedRatio.toStringAsFixed(1)} parts powder to 1 part citric',
                        ),
                      ),
                    ),
                  const SizedBox(
                    height: 16,
                  ),
                  if (pressingEntries.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Slider(
                          value: selectedRatio,
                          min: 1,
                          max: 15,
                          divisions:
                              14, // This allows for whole number steps from 1 to 15
                          label: selectedRatio.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              selectedRatio = value;
                              ratioTextFieldValue =
                                  selectedRatio.toStringAsFixed(
                                1,
                              ); // Keep the TextField in sync
                              // Update the citric amounts
                              for (final entry in pressingEntries) {
                                final systemGValue = double.tryParse(
                                      entry.systemGController.text,
                                    ) ??
                                    0.0;
                                entry.systemCitricController.text =
                                    (systemGValue / selectedRatio)
                                        .toStringAsFixed(2);
                              }
                            });
                          },
                        ),
                        if (pressingEntries.isNotEmpty)
                          Container(
                            width: MediaQuery.sizeOf(context).width * 0.22,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(33),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.5),
                                  offset: const Offset(-2, 2.5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: TextEditingController(
                                text: ratioTextFieldValue,
                              ),
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                hintText: 'Ratio',
                                filled: true,
                                fillColor: Colors.orange[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    33,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                labelText: 'Ratio',
                                labelStyle: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onSubmitted: (value) {
                                final manualInput = double.tryParse(value);
                                if (manualInput != null &&
                                    manualInput >= 1 &&
                                    manualInput <= 15) {
                                  setState(() {
                                    selectedRatio = manualInput;
                                    ratioTextFieldValue =
                                        value; // Ensure the TextField is updated
                                    // Update the citric amounts
                                    for (final entry in pressingEntries) {
                                      final systemGValue = double.tryParse(
                                            entry.systemGController.text,
                                          ) ??
                                          0.0;
                                      entry.systemCitricController.text =
                                          (systemGValue / selectedRatio)
                                              .toStringAsFixed(2);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  if (pressingEntries.isNotEmpty)
                    const SizedBox(
                      height: 16,
                    ),
                  if (pressingEntries.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Powder container
                        Container(
                          decoration: BoxDecoration(
                            gradient: const SweepGradient(
                              colors: [
                                Colors.red,
                                Colors.orange,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue,
                                Colors.indigo,
                                Colors.purple,
                                Colors.pink,
                                Colors.red,
                              ],
                            ),

                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(33),
                              topLeft: Radius.circular(33),
                            ),
                            // Applying a shadow that matches the rainbow theme might be tricky,
                            // but you can choose a color that stands out or complements it.
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withValues(alpha: 0.5),
                                offset: const Offset(-2, 2.5),
                                blurRadius:
                                    8, // You can adjust blurRadius for a more pronounced shadow
                              ),
                            ],
                          ),
                          width: MediaQuery.of(context).size.width *
                              0.66 *
                              (selectedRatio /
                                  (selectedRatio +
                                      1)), // Dynamic width based on the ratio
                          height: 50,
                          child: const Center(
                            child: Text(
                              'Powder',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        // Citric container
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(33),
                              topRight: Radius.circular(33),
                            ),
                          ),
                          width: MediaQuery.of(context).size.width * 0.66 -
                              MediaQuery.of(context).size.width *
                                  0.66 *
                                  (selectedRatio /
                                      (selectedRatio +
                                          1)), // Fixed width for citric
                          height: 50,

                          child: const Center(
                            child: Text(
                              'Citric',
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (pressingEntries.isNotEmpty)
                    const SizedBox(
                      height: 16,
                    ),
                  if (pressingEntries.isNotEmpty)
                    const Divider(
                      height: 2,
                      color: Colors.grey,
                    ),
                  if (pressingEntries.isNotEmpty)
                    const SizedBox(
                      height: 16,
                    ),
                  if (pressingEntries.isNotEmpty)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow[100]!.withValues(alpha: 0.8),
                            offset: const Offset(4, -2.5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: Colors.yellow[500]!.withValues(alpha: 0.8),
                        leading: const Icon(Icons.info_outline_rounded),
                        title:
                            const Text('Add amount in grams per one bath bomb'),
                      ),
                    ),
                  const SizedBox(
                    height: 16,
                  ),
                  Flexible(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: pressingEntries.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller:
                                    pressingEntries[index].colorController,
                                hintText: 'Color $index',
                                labelText: 'Color $index',
                                onChanged: (newValue) {
                                  // Assuming you have a way to update the corresponding PressingEntry object
                                  // This example directly updates the controller, but you might need additional logic
                                  // to ensure your model (if you have one) is also updated accordingly
                                  setState(() {
                                    pressingEntries[index]
                                        .colorController
                                        .text = newValue;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: CustomTextField(
                                controller:
                                    pressingEntries[index].systemGController,
                                hintText: 'Powder',
                                labelText: 'Powder',
                                onChanged: (newValue) {
                                  // Assuming you have a way to update the corresponding PressingEntry object
                                  // This example directly updates the controller, but you might need additional logic
                                  // to ensure your model (if you have one) is also updated accordingly
                                  setState(() {
                                    pressingEntries[index]
                                        .systemGController
                                        .text = newValue;
                                  });
                                },
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                            if (custom)
                              Expanded(
                                  child: CustomTextField(
                                      controller: pressingEntries[index]
                                          .systemCitricController,
                                      hintText: 'Citric',
                                      labelText: 'Citric',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true,),),),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  // Remove the pressingEntry at this index
                                  pressingEntries.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Custom Citric Amount?'),
                      Checkbox(
                        value: custom,
                        onChanged: (value) {
                          setState(() {
                            custom = value ?? false;
                            if (custom) {
                              for (final entry in pressingEntries) {
                                final systemGValue = double.tryParse(
                                      entry.systemGController.text,
                                    ) ??
                                    0.0;
                                entry.systemCitricController.text =
                                    (systemGValue / selectedRatio)
                                        .toStringAsFixed(2);
                              }
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width * 0.33,
                    child: IconButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateColor.resolveWith(
                          (states) => Colors.greenAccent.withValues(alpha: 0.8),
                        ),
                      ),
                      icon: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Add color'),
                          const SizedBox(
                            width: 8,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const SweepGradient(
                                colors: [
                                  Colors.red,
                                  Colors.orange,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.blue,
                                  Colors.indigo,
                                  Colors.purple,
                                  Colors.pink,
                                ],
                              ),

                              borderRadius: const BorderRadius.all(
                                Radius.circular(33),
                              ),
                              // Applying a shadow that matches the rainbow theme might be tricky,
                              // but you can choose a color that stands out or complements it.
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withValues(alpha: 0.5),
                                  offset: const Offset(-2, 2.5),
                                  blurRadius:
                                      8, // You can adjust blurRadius for a more pronounced shadow
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.transparent,
                            ), // Icon color changed to white for better visibility
                          ),
                        ],
                      ),
                      color: Colors.brown,
                      onPressed: () => addPressingEntry(setState),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Save'),
                        onPressed: () async {
                          // Parse the target from its text field
                          // Parse the target from its text field
                          final updatedTarget =
                          int.parse(targetController.text);

                          // Convert the pressingEntries back into a list of Pressing objects
                          final updatedPressings = pressingEntries.map((entry) {
                            final systemGValue =
                                double.tryParse(entry.systemGController.text) ??
                                    0.0;
                            final systemCitricValue = custom
                                ? double.tryParse(
                              entry.systemCitricController.text,
                            ) ??
                                0.0
                                : systemGValue / selectedRatio;
                            return Pressing(
                              entry.colorController.text,
                              systemGValue,
                              systemCitricValue,
                            );
                          }).toList();

                          // Construct an updated ProductInfo object
                          final updatedProduct = product.copyWith(
                            target: updatedTarget,
                            product: updatedPressings,
                            ayr: ayr,
                          );
                          final result = await ref
                              .read(productInfoProvider.notifier)
                              .editProductInfo(updatedProduct);
                          await ref
                              .read(lastSelectedProductProvider.notifier)
                              .deleteSelectedProductByName(
                            product.productName,);
                          await ref.read(lastSelectedProductProvider.notifier).saveSelectedProduct(updatedProduct);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (result) {
                              // Ensure the context is still valid before using it
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Product info updated succesfully.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              context.pop();
                              FocusScope.of(context).unfocus();
                            } else {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to update product info.',
                                  ),
                                  backgroundColor: Colors.greenAccent,
                                ),
                              );
                              context.pop();
                              FocusScope.of(context).unfocus();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ),
    ),
  );
}

class PressingEntry {
  PressingEntry({
    String color = '',
    double systemG = 0.0,
    double systemCitric = 0.0,
  })  : colorController = TextEditingController(text: color),
        systemGController =
            TextEditingController(text: systemG.toStringAsFixed(2)),
        systemCitricController =
            TextEditingController(text: systemCitric.toStringAsFixed(2));

  // Add a factory constructor to create a PressingEntry from a Pressing
  factory PressingEntry.fromPressing(Pressing pressing) => PressingEntry(
        color: pressing.productColor,
        systemG: pressing.systemG,
        systemCitric: pressing.systemCitric,
      );

  final TextEditingController colorController;
  final TextEditingController systemGController;
  final TextEditingController systemCitricController;
}
