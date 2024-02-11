import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitCheck extends ConsumerStatefulWidget {
  const SplitCheck({super.key, this.requiredAmount = 0});
  final int requiredAmount;

  @override
  SplitCheckState createState() => SplitCheckState();
}

class SplitCheckState extends ConsumerState<SplitCheck> {
  late TextEditingController targetController;
  late TextEditingController productNameController;
  late TextEditingController amountPerBatchController;
  late FocusNode focusNodeTarget;
  late FocusNode focusNodeAmount;

  @override
  void initState() {
    super.initState();
    focusNodeTarget = FocusNode();
    focusNodeAmount = FocusNode();
    targetController =
        TextEditingController(text: widget.requiredAmount.toString());
    productNameController = TextEditingController();
    final workingHours = ref.read(userNotifierProvider).workingHours ?? 0.0;
    amountPerBatchController = TextEditingController(
      text: (widget.requiredAmount > 0
          ? (widget.requiredAmount / (workingHours == 3.75 ? 6 : 12))
              .toStringAsFixed(0)
          : ''),
    );
    final productName = ref.read(selectedProductProvider).state;
    productNameController.text = productName;
  }

  @override
  void dispose() {
    focusNodeTarget.dispose();
    focusNodeAmount.dispose();
    targetController.dispose();
    productNameController.dispose();
    amountPerBatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(requiredAmountProvider)
      ..watch(amountPerBatchProvider)
      ..watch(selectedProductProvider);

    final products = ref.watch(productInfoProvider); // Directly use the state
    final productInfo = ref.watch(focusedProductProvider);
    final hasProducts = productInfo.product.isNotEmpty;

    final requiredAmount = double.tryParse(targetController.text) ?? 0.0;
    final amountPerBatch =
        double.tryParse(amountPerBatchController.text) ?? 0.0;
    final rounds =
        amountPerBatch != 0 ? (requiredAmount / amountPerBatch).floor() : 0;
    final extraBombs =
        amountPerBatch != 0 ? (requiredAmount % amountPerBatch) : 0;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/target_screen.jpg',
            fit: BoxFit.cover,
          ),
        ),
        GestureDetector(
          onTap: () {
            focusNodeTarget.unfocus();
            focusNodeAmount.unfocus();
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
            ),
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Autocomplete<ProductInfo>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<ProductInfo>.empty();
                        }
                        // Assuming `products` is a List<ProductInfo>
                        return products.where(
                          (productInfo) => productInfo.productName
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()),
                        );
                      },
                      onSelected: (selection) {
                        productNameController.text = selection.productName;
                        ref.read(searchTermProvider.notifier).state =
                            selection.productName;
                        ref.read(focusedProductProvider.notifier).state =
                            selection;
                        targetController.text = selection.target.toString();
                      },
                      displayStringForOption: (option) => option.productName,
                      fieldViewBuilder: (
                        context,
                        textEditingController,
                        focusNode,
                        onFieldSubmitted,
                      ) =>
                          TextField(
                        controller: productNameController,
                        focusNode: focusNode,
                        onChanged: (value) {
                          ref.read(searchTermProvider.notifier).state = value;
                          productNameController.text = value;
                          textEditingController.text = value;
                        },
                        style: const TextStyle(
                          color: Colors
                              .lightBlueAccent, // Set the color of entered text
                          fontSize: 20, // Set the font size of entered text
                          fontWeight: FontWeight
                              .bold, // Set the font weight of entered text
                        ),
                        decoration: InputDecoration(
                          labelText: 'Product name',
                          labelStyle: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold, // Bold text
                            fontSize: 18, // Slightly bigger font
                          ),
                          hintText: 'Add product name',
                          hintStyle: TextStyle(
                            color: Colors.lightBlueAccent.withOpacity(0.5),
                            fontWeight: FontWeight.bold, // Bold text
                            fontSize: 20, // Slightly bigger font
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.lightBlueAccent.withOpacity(0.7),
                              width: 4, // Bolder border
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Colors.lightBlueAccent.withOpacity(0.5),
                              width: 4, // Bolder border
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 4, // Bolder border
                            ),
                          ),
                          suffixIcon: Visibility(
                            visible: productNameController.text.isNotEmpty,
                            child: IconButton(
                              onPressed: () {
                                focusNode.unfocus();
                              },
                              icon: Icon(
                                Icons.keyboard_hide,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextField(
                            controller: targetController,
                            focusNode: focusNodeTarget,
                            onChanged: (value) => targetController.text = value,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              color: Colors
                                  .lightBlueAccent, // Set the color of entered text
                              fontSize: 20, // Set the font size of entered text
                              fontWeight: FontWeight
                                  .bold, // Set the font weight of entered text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Target',
                              labelStyle: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 18, // Slightly bigger font
                              ),
                              hintText: 'Add target',
                              hintStyle: TextStyle(
                                color: Colors.lightBlueAccent.withOpacity(0.5),
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 20, // Slightly bigger font
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      Colors.lightBlueAccent.withOpacity(0.7),
                                  width: 4, // Bolder border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      Colors.lightBlueAccent.withOpacity(0.5),
                                  width: 4, // Bolder border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 4, // Bolder border
                                ),
                              ), // Hint text color
                              suffixIcon: Visibility(
                                visible: targetController.text.isNotEmpty,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.blue[800],
                                  ),
                                  onPressed: () {
                                    targetController.clear();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: TextField(
                            focusNode: focusNodeAmount,
                            controller: amountPerBatchController,
                            style: const TextStyle(
                              color: Colors
                                  .lightBlueAccent, // Set the color of entered text
                              fontSize: 20, // Set the font size of entered text
                              fontWeight: FontWeight
                                  .bold, // Set the font weight of entered text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount per batch',
                              labelStyle: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 18, // Slightly bigger font
                              ),
                              hintText: 'Enter amount',
                              hintStyle: TextStyle(
                                color: Colors.lightBlueAccent.withOpacity(0.5),
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 20, // Slightly bigger font
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      Colors.lightBlueAccent.withOpacity(0.7),
                                  width: 4, // Bolder border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      Colors.lightBlueAccent.withOpacity(0.5),
                                  width: 4, // Bolder border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 4, // Bolder border
                                ),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final amount = int.tryParse(value) ?? 0;
                              ref.read(amountPerBatchProvider.notifier).state =
                                  amount;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              'Batches: $rounds',
                            ),
                            Text(
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              'Extra Bombs: $extraBombs',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: hasProducts ? productInfo.product.length : 0,
                      itemBuilder: (context, index) {
                        final product = productInfo;
                        final systemG =
                            ((product.product[index].systemG * amountPerBatch) /
                                    1000)
                                .toStringAsFixed(2);
                        final citricG = ((product.product[index].systemCitric *
                                    amountPerBatch) /
                                1000)
                            .toStringAsFixed(2);

                        String extractColorName(String colorString) {
                          if (colorString.contains('-')) {
                            return colorString.split('-').last.trim();
                          } else {
                            return colorString.split(' ').last.trim();
                          }
                        }

                        final color = getColorFromString(
                          extractColorName(product.product[index].productColor),
                        );
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: getColorFromString(
                                extractColorName(
                                  product.product[index].productColor,
                                ),
                                accent: true,
                              ),
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
                                  SizedBox(
                                    width:
                                        MediaQuery.sizeOf(context).width * 0.25,
                                    child: Center(
                                      child: Text(
                                        extractColorName(
                                          product.product[index].productColor,
                                        ),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Powder: $systemG kg',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        'Citric: $citricG kg',
                                        style: const TextStyle(
                                          fontSize: 20,
                                        ),
                                      ),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}
