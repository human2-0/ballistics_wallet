import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
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
  List<PressingEntry> pressingEntries = []; // Start with one entry
  double selectedRatio = 3;
  String ratioTextFieldValue = '3.0';
  final TextEditingController targetController = TextEditingController();
  final TextEditingController weightRangeController = TextEditingController();
  final TextEditingController ratioController = TextEditingController(
    text: '3.0',
  );
  bool custom = false;
  bool ayr = false;
  late final TextEditingController productNameController;

  @override
  void initState() {
    productNameController = TextEditingController(
      text: ref.read(productNameControllerProvider.notifier).controller.text,
    );
    super.initState();
  }

  @override
  void dispose() {
    targetController.dispose();
    weightRangeController.dispose();
    ratioController.dispose();
    productNameController.dispose();
    _disposePressingEntries();
    super.dispose();
  }

  // Method to add a new pressing entry
  void addPressingEntry(StateSetter setState) {
    setState(() {
      pressingEntries.add(PressingEntry());
    });
  }

  void _disposePressingEntries() {
    for (final entry in pressingEntries) {
      entry.dispose();
    }
    pressingEntries.clear();
  }

  void populateCitricController() {
    for (final entry in pressingEntries) {
      if (!custom) {
        final systemGValue =
            double.tryParse(entry.systemGController.text) ?? 0.0;
        entry.systemCitricController.text = (systemGValue / selectedRatio)
            .toStringAsFixed(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Material(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(33),
          child: ListTile(
            title: const Text("Not found what you're looking for?"),
            trailing: Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
                  stops: const [0.0, 0.5, 0.9],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(33)),
              ),
              child: IconButton(
                icon: const Icon(Icons.add),
                color: Colors.brown[400],
                tooltip: 'Add product',
                onPressed: () async {
                  productNameController.text =
                      ref
                          .read(productNameControllerProvider.notifier)
                          .controller
                          .text;
                  try {
                    await showDialog<Widget>(
                      context: context,
                      builder:
                          (dialogContext) => StatefulBuilder(
                            // Wrap the dialog content with StatefulBuilder
                            builder:
                                (context, setState) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Dialog(
                                    insetPadding: const EdgeInsets.all(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Text(
                                              'Add a new product',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            const SizedBox(height: 16),
                                            CustomTextField(
                                              controller: productNameController,
                                              hintText: 'Product Name',
                                              labelText: 'Product Name',
                                              selectAllOnFocus: true,
                                            ),
                                            const SizedBox(height: 16),
                                            CustomTextField(
                                              controller: targetController,
                                              hintText: 'Target',
                                              labelText: 'Target',
                                              keyboardType:
                                                  TextInputType.number,
                                              selectAllOnFocus: true,
                                            ),
                                            const SizedBox(height: 16),
                                            CustomTextField(
                                              controller: weightRangeController,
                                              hintText: '120-130',
                                              labelText: 'Weight range (g)',
                                            ),
                                            if (pressingEntries.isNotEmpty)
                                              const SizedBox(height: 16),
                                            if (pressingEntries.isNotEmpty)
                                              const Divider(
                                                height: 2,
                                                color: Colors.grey,
                                              ),
                                            if (pressingEntries.isNotEmpty)
                                              const SizedBox(height: 16),
                                            if (pressingEntries.isNotEmpty)
                                              DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.yellow[100]!
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      offset: const Offset(
                                                        4,
                                                        -2.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  tileColor: Colors.yellow[500]!
                                                      .withValues(alpha: 0.8),
                                                  leading: const Icon(
                                                    Icons.info_outline_rounded,
                                                  ),
                                                  title: Text(
                                                    'Ratio: ${selectedRatio.toStringAsFixed(1)} parts powder to 1 part citric',
                                                  ),
                                                ),
                                              ),
                                            if (pressingEntries.isNotEmpty)
                                              const SizedBox(height: 16),
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
                                                    divisions: 14,
                                                    label: selectedRatio
                                                        .toStringAsFixed(1),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        selectedRatio = value;
                                                        ratioTextFieldValue =
                                                            selectedRatio
                                                                .toStringAsFixed(
                                                                  1,
                                                                );
                                                        ratioController.text =
                                                            ratioTextFieldValue;
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
                                                              .toStringAsFixed(
                                                                2,
                                                              );
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  Container(
                                                    width:
                                                        MediaQuery.sizeOf(
                                                          context,
                                                        ).width *
                                                        0.26,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                            Radius.circular(33),
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.orange
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          offset: const Offset(
                                                            -2,
                                                            2.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          ratioController,
                                                      decoration: InputDecoration(
                                                        alignLabelWithHint:
                                                            true,
                                                        hintText: 'Ratio',
                                                        filled: true,
                                                        fillColor:
                                                            Colors.orange[100],
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                33,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        labelText: 'Ratio',
                                                        labelStyle:
                                                            const TextStyle(
                                                              fontSize: 18,
                                                            ),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      onSubmitted: (value) {
                                                        final manualInput =
                                                            double.tryParse(
                                                              value,
                                                            );
                                                        if (manualInput !=
                                                                null &&
                                                            manualInput >= 1 &&
                                                            manualInput <= 15) {
                                                          setState(() {
                                                            selectedRatio =
                                                                manualInput;
                                                            ratioTextFieldValue =
                                                                value;
                                                            ratioController
                                                                .text = value;
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
                                                                  .toStringAsFixed(
                                                                    2,
                                                                  );
                                                            }
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 16),
                                            if (pressingEntries.isNotEmpty)
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const SweepGradient(
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
                                                            bottomLeft:
                                                                Radius.circular(
                                                                  33,
                                                                ),
                                                            topLeft:
                                                                Radius.circular(
                                                                  33,
                                                                ),
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors
                                                              .deepPurple
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          offset: const Offset(
                                                            -2,
                                                            2.5,
                                                          ),
                                                          blurRadius: 8,
                                                        ),
                                                      ],
                                                    ),
                                                    width:
                                                        MediaQuery.of(
                                                          context,
                                                        ).size.width *
                                                        0.66 *
                                                        (selectedRatio /
                                                            (selectedRatio +
                                                                1)),
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
                                                  Container(
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                            bottomRight:
                                                                Radius.circular(
                                                                  33,
                                                                ),
                                                            topRight:
                                                                Radius.circular(
                                                                  33,
                                                                ),
                                                          ),
                                                    ),
                                                    width:
                                                        MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.66 -
                                                        MediaQuery.of(
                                                              context,
                                                            ).size.width *
                                                            0.66 *
                                                            (selectedRatio /
                                                                (selectedRatio +
                                                                    1)),
                                                    height: 50,
                                                    child: const Center(
                                                      child: Text('Citric'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 16),
                                            if (pressingEntries.isNotEmpty)
                                              const Divider(
                                                height: 2,
                                                color: Colors.grey,
                                              ),
                                            const SizedBox(height: 16),
                                            if (pressingEntries.isNotEmpty)
                                              DecoratedBox(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.yellow[100]!
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      offset: const Offset(
                                                        4,
                                                        -2.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  tileColor: Colors.yellow[500]!
                                                      .withValues(alpha: 0.8),
                                                  leading: const Icon(
                                                    Icons.info_outline_rounded,
                                                  ),
                                                  title: const Text(
                                                    'Add amount in grams per one bath bomb',
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 16),
                                            Flexible(
                                              child: ListView.builder(
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    pressingEntries.length,
                                                itemBuilder:
                                                    (context, index) => Padding(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            0,
                                                            0,
                                                            0,
                                                            16,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: CustomTextField(
                                                              controller:
                                                                  pressingEntries[index]
                                                                      .colorController,
                                                              focusNode:
                                                                  pressingEntries[index]
                                                                      .colorFocusNode,
                                                              hintText:
                                                                  'Color ${index + 1}',
                                                              labelText:
                                                                  'Color ${index + 1}',
                                                              selectAllOnFocus:
                                                                  true,
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: CustomTextField(
                                                              controller:
                                                                  pressingEntries[index]
                                                                      .systemGController,
                                                              focusNode:
                                                                  pressingEntries[index]
                                                                      .systemGFocusNode,
                                                              hintText:
                                                                  'Powder',
                                                              labelText:
                                                                  'Powder',
                                                              keyboardType:
                                                                  const TextInputType.numberWithOptions(
                                                                    decimal:
                                                                        true,
                                                                  ),
                                                              selectAllOnFocus:
                                                                  true,
                                                            ),
                                                          ),
                                                          if (custom)
                                                            Expanded(
                                                              child: CustomTextField(
                                                                controller:
                                                                    pressingEntries[index]
                                                                        .systemCitricController,
                                                                focusNode:
                                                                    pressingEntries[index]
                                                                        .systemCitricFocusNode,
                                                                hintText:
                                                                    'Citric',
                                                                labelText:
                                                                    'Citric',
                                                                keyboardType:
                                                                    const TextInputType.numberWithOptions(
                                                                      decimal:
                                                                          true,
                                                                    ),
                                                                selectAllOnFocus:
                                                                    true,
                                                              ),
                                                            ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .remove_circle_outline,
                                                              color: Colors.red,
                                                            ),
                                                            onPressed: () {
                                                              final entry =
                                                                  pressingEntries[index];
                                                              setState(() {
                                                                pressingEntries
                                                                    .removeAt(
                                                                      index,
                                                                    );
                                                              });
                                                              WidgetsBinding
                                                                  .instance
                                                                  .addPostFrameCallback((
                                                                    _,
                                                                  ) {
                                                                    entry
                                                                        .dispose();
                                                                  });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            if (pressingEntries.isNotEmpty)
                                              Row(
                                                children: [
                                                  const Text(
                                                    'Custom Citric Amount?',
                                                  ),
                                                  Checkbox(
                                                    value: custom,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        populateCitricController();
                                                        custom = value!;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            SizedBox(
                                              width:
                                                  MediaQuery.sizeOf(
                                                    context,
                                                  ).width *
                                                  0.33,
                                              child: IconButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateColor.resolveWith(
                                                        (states) => Colors
                                                            .greenAccent
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                ),
                                                icon: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text('Add powder'),
                                                    const SizedBox(width: 8),
                                                    DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const SweepGradient(
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
                                                              Radius.circular(
                                                                33,
                                                              ),
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .deepPurple
                                                                .withValues(
                                                                  alpha: 0.8,
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  -2,
                                                                  2.5,
                                                                ),
                                                            blurRadius: 8,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                color: Colors.brown,
                                                onPressed:
                                                    () => addPressingEntry(
                                                      setState,
                                                    ),
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
                                                        productNameController
                                                            .text
                                                            .trim();
                                                    final targetString =
                                                        targetController.text
                                                            .trim();
                                                    if (targetString.isEmpty) {
                                                      showAppNotification(
                                                        context,
                                                        'Target is required.',
                                                        type:
                                                            AppNotificationType
                                                                .error,
                                                      );
                                                      return;
                                                    }

                                                    final target = int.tryParse(
                                                      targetString,
                                                    );
                                                    if (target == null) {
                                                      showAppNotification(
                                                        context,
                                                        'Invalid target value.',
                                                        type:
                                                            AppNotificationType
                                                                .error,
                                                      );
                                                      return;
                                                    }
                                                    final customWeightRange =
                                                        _parseWeightRange(
                                                          weightRangeController
                                                              .text
                                                              .trim(),
                                                        );
                                                    if (customWeightRange ==
                                                            null &&
                                                        weightRangeController
                                                            .text
                                                            .trim()
                                                            .isNotEmpty) {
                                                      showAppNotification(
                                                        context,
                                                        'Use weight range like 120-130.',
                                                        type:
                                                            AppNotificationType
                                                                .error,
                                                      );
                                                      return;
                                                    }

                                                    final pressings =
                                                        pressingEntries.map((
                                                          entry,
                                                        ) {
                                                          final powderAmount =
                                                              double.tryParse(
                                                                entry
                                                                    .systemGController
                                                                    .text,
                                                              ) ??
                                                              0;
                                                          final citricAmount =
                                                              double.tryParse(
                                                                entry
                                                                    .systemCitricController
                                                                    .text,
                                                              ) ??
                                                              0;

                                                          return Pressing(
                                                            entry
                                                                .colorController
                                                                .text,
                                                            powderAmount,
                                                            custom
                                                                ? citricAmount
                                                                : powderAmount /
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
                                                            customWeightRangeMinGrams:
                                                                customWeightRange
                                                                    ?.minGrams,
                                                            customWeightRangeMaxGrams:
                                                                customWeightRange
                                                                    ?.maxGrams,
                                                          );
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      if (!mounted) return;
                                                      showAppNotification(
                                                        context,
                                                        'Product added.',
                                                        type:
                                                            AppNotificationType
                                                                .success,
                                                      );
                                                    } on FormatException catch (
                                                      e
                                                    ) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      showAppNotification(
                                                        context,
                                                        e.message,
                                                        type:
                                                            AppNotificationType
                                                                .error,
                                                      );
                                                      return;
                                                    }
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
                          ),
                    );
                  } finally {
                    _disposePressingEntries();
                    targetController.clear();
                    weightRangeController.clear();
                    selectedRatio = 3;
                    ratioTextFieldValue = '3.0';
                    ratioController.text = ratioTextFieldValue;
                    custom = false;
                  }
                },
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

_ParsedWeightRange? _parseWeightRange(String value) {
  if (value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 2) return null;
  final minGrams = double.tryParse(parts[0].trim());
  final maxGrams = double.tryParse(parts[1].trim());
  if (minGrams == null || maxGrams == null) return null;
  if (minGrams <= 0 || maxGrams <= 0 || minGrams > maxGrams) return null;
  return _ParsedWeightRange(minGrams, maxGrams);
}

class _ParsedWeightRange {
  const _ParsedWeightRange(this.minGrams, this.maxGrams);

  final double minGrams;
  final double maxGrams;
}

class PressingEntry {
  PressingEntry()
    : colorController = TextEditingController(),
      systemGController = TextEditingController(text: '0.00'),
      systemCitricController = TextEditingController(text: '0.00'),
      colorFocusNode = FocusNode(),
      systemGFocusNode = FocusNode(),
      systemCitricFocusNode = FocusNode();
  final TextEditingController colorController;
  final TextEditingController systemGController;
  final TextEditingController systemCitricController;
  final FocusNode colorFocusNode;
  final FocusNode systemGFocusNode;
  final FocusNode systemCitricFocusNode;

  void dispose() {
    colorController.dispose();
    systemGController.dispose();
    systemCitricController.dispose();
    colorFocusNode.dispose();
    systemGFocusNode.dispose();
    systemCitricFocusNode.dispose();
  }
}
