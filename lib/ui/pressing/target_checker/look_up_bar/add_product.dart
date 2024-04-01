import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends ConsumerState<AddProductDialog> {
  // final TextEditingController productNameController = TextEditingController();


  List<PressingEntry> pressingEntries = []; // Start with one entry

  // Method to add a new pressing entry
  void addPressingEntry(StateSetter setState) {
    setState(() {
      pressingEntries.add(PressingEntry());
    });
  }

  double selectedRatio = 3; // Example initial ratio value
  String ratioTextFieldValue = '3.0';

  @override
  Widget build(BuildContext context) {

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
                  await showDialog<Widget>(
                    context: context,
                    builder: (context) => Dialog(
                      child: StatefulBuilder(
                        // Wrap the dialog content with StatefulBuilder
                        builder: (context, setState) {
                          final targetController = TextEditingController();
                          final productNameController =
                              ref.read(productNameControllerProvider.notifier).controller;
                          return SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    'Add a new product',
                                    style: TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  customTextField(
                                    controller: productNameController,
                                    hintText: 'Product Name',
                                    labelText: 'Product Name',
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  customTextField(
                                    controller: targetController,
                                    hintText: 'Target',
                                    labelText: 'Target',
                                    keyboardType: TextInputType.number,
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
                                            color: Colors.yellow[100]!
                                                .withOpacity(0.8),
                                            offset: const Offset(4, -2.5),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        tileColor: Colors.yellow[500]!
                                            .withOpacity(0.8),
                                        leading: const Icon(
                                          Icons.info_outline_rounded,
                                        ),
                                        title: Text(
                                          'Ratio: ${selectedRatio.toStringAsFixed(1)} parts powder to 1 part citric',
                                        ),
                                      ),
                                    ),
                                  if (pressingEntries.isNotEmpty)const SizedBox(
                                    height: 16,
                                  ),
                                  if (pressingEntries.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Slider(
                                          value: selectedRatio,
                                          min: 1,
                                          max: 15,
                                          divisions:
                                              14, // This allows for whole number steps from 1 to 15
                                          label: selectedRatio
                                              .toStringAsFixed(1),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedRatio = value;
                                              ratioTextFieldValue =
                                                  selectedRatio
                                                      .toStringAsFixed(
                                                1,
                                              ); // Keep the TextField in sync
                                              // Update the citric amounts
                                              for (final entry
                                                  in pressingEntries) {
                                                final systemGValue =
                                                    double.tryParse(
                                                          entry
                                                              .systemGController
                                                              .text,
                                                        ) ??
                                                        0.0;
                                                entry.systemCitricController
                                                    .text = (systemGValue /
                                                        selectedRatio)
                                                    .toStringAsFixed(2);
                                              }
                                            });
                                          },
                                        ),
                                        Container(
                                          width: MediaQuery.sizeOf(context)
                                                  .width *
                                              0.26,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.all(
                                              Radius.circular(33),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.orange
                                                    .withOpacity(0.5),
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
                                                borderRadius:
                                                    BorderRadius.circular(
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
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            onSubmitted: (value) {
                                              final manualInput =
                                                  double.tryParse(value);
                                              if (manualInput != null &&
                                                  manualInput >= 1 &&
                                                  manualInput <= 15) {
                                                setState(() {
                                                  selectedRatio = manualInput;
                                                  ratioTextFieldValue =
                                                      value; // Ensure the TextField is updated
                                                  // Update the citric amounts
                                                  for (final entry
                                                      in pressingEntries) {
                                                    final systemGValue =
                                                        double.tryParse(
                                                              entry
                                                                  .systemGController
                                                                  .text,
                                                            ) ??
                                                            0.0;
                                                    entry
                                                        .systemCitricController
                                                        .text = (systemGValue /
                                                            selectedRatio)
                                                        .toStringAsFixed(2);
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  if (pressingEntries.isNotEmpty)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(33),
                                              topLeft: Radius.circular(33),
                                            ),
                                            // Applying a shadow that matches the rainbow theme might be tricky,
                                            // but you can choose a color that stands out or complements it.
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.deepPurple
                                                    .withOpacity(
                                                  0.5,
                                                ), // Example shadow color
                                                offset: const Offset(-2, 2.5),
                                                blurRadius:
                                                    8, // You can adjust blurRadius for a more pronounced shadow
                                              ),
                                            ],
                                          ),
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.66 *
                                              (selectedRatio /
                                                  (selectedRatio +
                                                      1)), // Dynamic width based on the ratio
                                          height: 50,
                                          child: const Center(
                                            child: Text(
                                              'Powder',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Citric container
                                        Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                              bottomRight:
                                                  Radius.circular(33),
                                              topRight: Radius.circular(33),
                                            ),
                                          ),
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.66 -
                                              MediaQuery.of(context)
                                                      .size
                                                      .width *
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
                                            color: Colors.yellow[100]!
                                                .withOpacity(0.8),
                                            offset: const Offset(4, -2.5),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        tileColor: Colors.yellow[500]!
                                            .withOpacity(0.8),
                                        leading: const Icon(
                                          Icons.info_outline_rounded,
                                        ),
                                        title: const Text(
                                          'Add amount in grams per one bath bomb',
                                        ),
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Flexible(
                                    child: ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: pressingEntries.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            0,
                                            16,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: customTextField(
                                                  controller:
                                                      pressingEntries[index]
                                                          .colorController,
                                                  hintText:
                                                      'Color ${index + 1}',
                                                  labelText:
                                                      'Color ${index + 1}',
                                                ),
                                              ),
                                              Expanded(
                                                child: customTextField(
                                                  controller:
                                                      pressingEntries[index]
                                                          .systemGController,
                                                  hintText: 'Powder',
                                                  labelText: 'Powder',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    // Remove the pressingEntry at this index
                                                    pressingEntries
                                                        .removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.sizeOf(context).width *
                                        0.33,
                                    child: IconButton(
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateColor.resolveWith(
                                          (states) =>
                                              Colors.greenAccent.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                      ),
                                      icon: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Add powder'),
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

                                              borderRadius:
                                                  const BorderRadius.all(
                                                Radius.circular(33),
                                              ),
                                              // Applying a shadow that matches the rainbow theme might be tricky,
                                              // but you can choose a color that stands out or complements it.
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.deepPurple
                                                      .withOpacity(
                                                    0.5,
                                                  ), // Example shadow color
                                                  offset:
                                                      const Offset(-2, 2.5),
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
                                      onPressed: () =>
                                          addPressingEntry(setState),
                                    ),
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
                                        child: const Text('Save'),
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
                                                    entry.systemGController
                                                        .text,
                                                  ) ??
                                                  0.0,
                                              double.tryParse(
                                                    entry.systemGController
                                                        .text,
                                                  )! /
                                                  selectedRatio,
                                            );
                                          }).toList();

                                          try {
                                            await ref
                                                .read(
                                                  productInfoProvider
                                                      .notifier,
                                                )
                                                .addProductInfo(
                                                  productName,
                                                  target,
                                                  pressings,
                                                );
                                            WidgetsBinding.instance
                                                .addPostFrameCallback(
                                                    (timeStamp) {
                                              Navigator.of(context).pop();
                                            });
                                          } on FormatException catch (e) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback(
                                                    (timeStamp) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Error: ${e.message}',
                                                  ),
                                                  behavior: SnackBarBehavior
                                                      .floating,
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
