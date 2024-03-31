import 'package:ballistics_wallet_flutter/custom_widgets/toast_widget.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PressingEntry {
  PressingEntry({String color = '', double systemG = 0.0, double systemCitric = 0.0})
      : colorController = TextEditingController(text: color),
        systemGController = TextEditingController(text: systemG.toStringAsFixed(2)),
        systemCitricController = TextEditingController(text: systemCitric.toStringAsFixed(2));

  // Add a factory constructor to create a PressingEntry from a Pressing
  factory PressingEntry.fromPressing(Pressing pressing) {
    return PressingEntry(
      color: pressing.productColor,
      systemG: pressing.systemG,
      systemCitric: pressing.systemCitric,
    );
  }

  final TextEditingController colorController;
  final TextEditingController systemGController;
  final TextEditingController systemCitricController;
}

// Dialog function
Future<void> showEditProductDialog(
    BuildContext context,
    WidgetRef ref, {
      required ProductInfo product,
    }) async {
  // Initialize the TextEditingControllers with the current product info
  final productNameController = TextEditingController(text: product.productName);
  final targetController = TextEditingController(text: product.target.toString());

  // Convert each Pressing into a PressingEntry for editing
  final pressingEntries = product.product.map((pressing) {
    return PressingEntry.fromPressing(pressing);
  }).toList();

  void addPressingEntry(StateSetter setState) {
    setState(() {
      pressingEntries.add(PressingEntry());
    });
  }

  await showDialog<Widget>(
    context: context,
    builder: (context) => Dialog(
      child: StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Edit product'),
                TextField(
                  enabled: false,
                  controller: productNameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Target',
                  ),
                  keyboardType: TextInputType.number,
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pressingEntries.length,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: pressingEntries[index].colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: pressingEntries[index].systemGController,
                              decoration: const InputDecoration(
                                labelText: 'Powder G',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: pressingEntries[index].systemCitricController,
                              decoration: const InputDecoration(
                                labelText: 'Citric G',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => addPressingEntry(setState),
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
                        final updatedTarget = int.parse(targetController.text);

                        // Convert the pressingEntries back into a list of Pressing objects
                        final updatedPressings = pressingEntries.map((entry) {
                          return Pressing(
                            entry.colorController.text,
                            double.tryParse(entry.systemGController.text) ?? 0.0,
                            double.tryParse(entry.systemCitricController.text) ?? 0.0,
                          );
                        }).toList();

                        // Construct an updated ProductInfo object
                        final updatedProduct = product.copyWith(
                          target: updatedTarget,
                          product: updatedPressings,
                        );
                        final result = await ref.read(productInfoProvider.notifier).editProductInfo(updatedProduct);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (result) {
                            // Ensure the context is still valid before using it
                            showToast(context, 'Product info updated successfully.', colors: [Colors.greenAccent, Colors.lightGreen[100]!]);
                            context.pop();
                          } else {
                            showToast(context, 'Failed to update product info.', colors: [Colors.redAccent, Colors.red[100]!]);
                            context.pop();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
