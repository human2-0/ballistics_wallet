import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends ConsumerState<AddProductDialog> {
  // final TextEditingController productNameController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  List<PressingEntry> pressingEntries = [
    PressingEntry(),
  ]; // Start with one entry

  // Method to add a new pressing entry
  void addPressingEntry(StateSetter setState) {
    setState(() {
      pressingEntries.add(PressingEntry());
    });
  }

  @override
  Widget build(BuildContext context) {
    final productNameController = ref.watch(textEditingControllerProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            color: Colors.white,
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ListTile(
            title: const Text("Not found what you're looking for?"),
            trailing: Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 16,
                    offset: const Offset(4, 4), // changes position of shadow
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[50]!,
                    Colors.orange[200]!,
                    Colors.orange[300]!,
                  ],
                  stops: const [
                    0.0,
                    0.5,
                    0.9,
                  ],
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(33),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                color: Colors.brown[400],
                tooltip: 'Add product',
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: StatefulBuilder(
                        // Wrap the dialog content with StatefulBuilder
                        builder: (context, setState) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Text('Add a new product'),
                                TextField(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: pressingEntries[index]
                                                  .colorController,
                                              decoration: const InputDecoration(
                                                labelText: 'Color',
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: pressingEntries[index]
                                                  .systemGController,
                                              decoration: const InputDecoration(
                                                labelText: 'Powder G',
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true,),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: pressingEntries[index]
                                                  .systemCitricController,
                                              decoration: const InputDecoration(
                                                labelText: 'Citric G',
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true,),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Add'),
                                      onPressed: () async {
                                        final productName =
                                            productNameController.text;
                                        final targetString =
                                            targetController.text;

                                        if (productName.isEmpty) {
                                          return;
                                        }

                                        final target =
                                            int.tryParse(targetString);
                                        if (target == null) {
                                          return;
                                        }

                                        final pressings =
                                            pressingEntries.map((entry) {
                                          return Pressing(
                                            entry.colorController.text,
                                            double.tryParse(
                                                  entry.systemGController.text,
                                                ) ??
                                                0.0,
                                            double.tryParse(
                                                  entry.systemCitricController
                                                      .text,
                                                ) ??
                                                0.0,
                                          );
                                        }).toList();

                                        try {
                                          await ref
                                              .read(
                                                productInfoProvider.notifier,
                                              )
                                              .addProductInfo(
                                                productName,
                                                target,
                                                pressings,
                                              );
                                          if (mounted) {
                                            Navigator.of(context).pop();
                                          }
                                        } on FormatException catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Error: ${e.message}'),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration:
                                                    const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
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
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PressingEntry {
  PressingEntry()
      : colorController = TextEditingController(),
        systemGController = TextEditingController(),
        systemCitricController = TextEditingController();
  TextEditingController colorController;
  TextEditingController systemGController;
  TextEditingController systemCitricController;
}
