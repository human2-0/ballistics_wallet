import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../models/product_split.dart';
import '../../../providers/split_providers.dart';

class SplitCheck extends ConsumerStatefulWidget {
  final int requiredAmount;

  const SplitCheck({super.key, this.requiredAmount = 0});

  @override
  _SplitCheckState createState() => _SplitCheckState();
}

class _SplitCheckState extends ConsumerState<SplitCheck> {
  late TextEditingController requiredAmountController;
  late TextEditingController productNameController;
  late TextEditingController amountPerBatchController;
  late Future<List<Product>> productsFuture;

  @override
  void initState() {
    super.initState();
    requiredAmountController =
        TextEditingController(text: widget.requiredAmount.toString());
    productNameController = TextEditingController();
    final double workingHours =
        ref.read(userNotifierProvider).workingHours ?? 0.0;
    amountPerBatchController = TextEditingController(
        text: ((widget.requiredAmount > 0
            ? (widget.requiredAmount / (workingHours == 3.75 ? 6 : 12))
                .toStringAsFixed(0)
            : '')));
    String productName = ref.read(selectedProductProvider).state;
    productsFuture = getProducts(productName);
    productNameController.text = productName;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String productName = ref.read(selectedProductProvider).state;
    final double workingHours =
        ref.read(userNotifierProvider).workingHours ?? 0.0;
    amountPerBatchController.text = ((widget.requiredAmount > 0
        ? (widget.requiredAmount / (workingHours == 3.75 ? 6 : 12))
            .toStringAsFixed(0)
        : ''));
    productsFuture = getProducts(productName);
  }

  @override
  void dispose() {
    requiredAmountController.dispose();
    productNameController.dispose();
    amountPerBatchController.dispose();
    super.dispose();
  }

  Future<List<Product>> getProducts(String productName) async {
    final box = await Hive.openBox<Product>('products_split');
    return box.values
        .where((product) => product.productName == productName)
        .toSet()
        .toList();
  }

  Future<List<Product>> getAllProducts() async {
    final box = await Hive.openBox<Product>('products_split');
    return box.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final requiredAmount = ref.watch(requiredAmountProvider);
    final amountPerBatch = ref.watch(amountPerBatchProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Center(child: Text('Split check')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Product>>(
          future: productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final products = snapshot.data!;

            final requiredAmount =
                double.tryParse(requiredAmountController.text) ?? 0.0;
            final amountPerBatch =
                double.tryParse(amountPerBatchController.text) ?? 0.0;
            final rounds = amountPerBatch != 0
                ? (requiredAmount / amountPerBatch).floor()
                : 0;
            final extraBombs =
                amountPerBatch != 0 ? (requiredAmount % amountPerBatch) : 0;
            products.sort((a, b) => ((b.systemG * amountPerBatch) / 1000).compareTo((a.systemG * amountPerBatch) / 1000));

            return SingleChildScrollView(
              child: Column(
                children: [
                  FutureBuilder<List<Product>>(
                      future: getAllProducts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final products = snapshot.data!;
                        return Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }
                            final uniqueProductNames = products
                                .map((product) => product.productName)
                                .toSet()
                                .toList();

                            return uniqueProductNames.where((productName) {
                              return productName
                                  .toLowerCase()
                                  .contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            productNameController.text = selection;
                            ref.read(selectedProductProvider).state = selection;
                            setState(() {
                              productsFuture = getProducts(selection);
                            });
                          },
                          displayStringForOption: (String option) => option,
                          fieldViewBuilder: (BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted) {
                            return TextField(
                              controller: productNameController,
                              focusNode: focusNode,
                              onChanged: (value) => textEditingController.text = value,
                              decoration: InputDecoration(
                                labelText: 'Product Name',
                                suffixIcon: Visibility(
                                  visible: productNameController.text.isNotEmpty,
                                  child: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      productNameController.clear();
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  TextField(
                    controller: requiredAmountController,
                    decoration:
                        const InputDecoration(labelText: 'Required Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      ref.read(requiredAmountProvider.notifier).state = amount;
                    },
                  ),
                  TextField(
                    controller: amountPerBatchController,
                    decoration:
                        const InputDecoration(labelText: 'Amount Per Batch'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = int.tryParse(value) ?? 0;
                      ref.read(amountPerBatchProvider.notifier).state = amount;
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(33),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent[100]!.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text('To achieve your goal:')),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Rounds: $rounds'),
                                  Text('Extra Bombs: $extraBombs'),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      Product product = products[index];
                      String systemG =
                          ((product.systemG * amountPerBatch) / 1000)
                              .toStringAsFixed(2);
                      String citricG =
                          ((product.systemCitric * amountPerBatch) / 1000)
                              .toStringAsFixed(2);

                      String extractColorName(String colorString) {
                        if (colorString.contains('-')) {
                          return colorString.split('-').last.trim();
                        } else {
                          return colorString.split(' ').last.trim();
                        }
                      }

                      final color = getColorFromString(extractColorName(product.productColor));
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: getColorFromString(
                                extractColorName(product.productColor),
                                accent: true),
                            borderRadius: BorderRadius.circular(33),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  width: MediaQuery.sizeOf(context).width * 0.25,
                                  child: Center(
                                    child: Text(
                                    extractColorName(product.productColor),
                                        style: const TextStyle(fontSize: 20)),
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      'Powder: $systemG kg',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    Text('Citric: $citricG kg',
                                        style: const TextStyle(
                                          fontSize: 20,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Color getColorFromString(String colorName, {bool accent = false}) {
  switch (colorName.toLowerCase()) {
    case 'red':
      return accent ? Colors.red : Colors.redAccent;
    case 'green':
      return accent ? Colors.green : Colors.greenAccent;
    case 'blue':
      return accent ? Colors.blue : Colors.blueAccent;
    case 'yellow':
      return accent ? Colors.yellow : Colors.yellowAccent;
    case 'orange':
      return accent ? Colors.orange : Colors.orangeAccent;
    case 'purple':
      return accent ? Colors.purple : Colors.purpleAccent;
    case 'pink':
      return accent ? Colors.pink : Colors.pinkAccent;
    case 'white':
      return accent ? Colors.black12 : Colors.white; // no whiteAccent exists
    default:
      return accent ? Colors.white : Colors.white70;
  }
}
