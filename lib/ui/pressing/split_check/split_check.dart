import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
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
  late TextEditingController amountPerBatchController;
  late FocusNode focusNodeTarget;
  late FocusNode focusNodeAmount;
  late FocusNode focusNodeAutocomplete;
  bool shouldUpdateTargetController = true;

  @override
  void initState() {
    super.initState();
    focusNodeTarget = FocusNode();
    focusNodeAmount = FocusNode();
    focusNodeAutocomplete = FocusNode();
    targetController =
        TextEditingController(text: widget.requiredAmount.toString());
    final workingHours = ref.read(userNotifierProvider).workingHours ?? 0.0;
    amountPerBatchController = TextEditingController(
      text: (widget.requiredAmount > 0
          ? (widget.requiredAmount / (workingHours == 3.75 ? 6 : 12))
              .toStringAsFixed(0)
          : ''),
    );

    focusNodeTarget.addListener(() {});
    focusNodeAmount.addListener(() {});

    // void onTargetChanged() {
    //   // Implement logic if needed when target changes. For example, you might want to reset the flag here.
    // }
    //
    // targetController.addListener(onTargetChanged);
  }

  @override
  void dispose() {
    focusNodeTarget.dispose();
    focusNodeAmount.dispose();
    targetController.dispose();
    amountPerBatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(requiredAmountProvider)
      ..watch(amountPerBatchProvider);

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

    if (shouldUpdateTargetController &&
        targetController.text != productInfo.target.toString()) {
      targetController.text = productInfo.target.toString();
      shouldUpdateTargetController = false; // Reset the flag after updating
    }

    final productNameController =
        ref.watch(productNameControllerProvider.notifier).controller;

    final userState = ref.watch(userNotifierProvider);
    final allowance = ref.watch(allowanceProvider);
    final workingHours = userState.workingHours ?? 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/target_screen.webp',
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
                    if (productInfo.productName.isNotEmpty)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors
                              .transparent, // Optional: background color of the box
                          borderRadius:
                              BorderRadius.circular(15), // Rounded corners
                          border: Border.all(
                            color: Colors.orangeAccent[100]!
                                .withOpacity(0.7), // Border color
                            width: 4, // Border thickness
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Text(
                                  productInfo.productName,
                                  style: TextStyle(
                                    color: Colors.orange[100],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateColor.resolveWith(
                                            (states) =>
                                                Colors.orangeAccent[100]!,),),
                                icon: Icon(Icons.clear,
                                    size: 30, color: Colors.deepOrange[800],),
                                onPressed: () {
                                  // Logic to clear the focused product
                                  ref
                                      .read(focusedProductProvider.notifier)
                                      .state = ProductInfo(
                                    productName: '',
                                    product: [const Pressing('', 0, 0)],
                                    imageName: 'question',
                                    target: 0,
                                  );
                                  // Optionally reset the productNameController if you use it for input
                                  productNameController.clear();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (productInfo.productName.isEmpty)
                      Autocomplete<ProductInfo>(
                        optionsBuilder: (textEditingValue) {
                          // Your filtering logic here
                          return products.where(
                            (productInfo) =>
                                productInfo.productName.toLowerCase().contains(
                                      textEditingValue.text.toLowerCase(),
                                    ),
                          );
                        },
                        displayStringForOption: (option) => option.productName,
                        onSelected: (selection) async {
                          final productTarget = ((selection.target.toDouble()) *
                                  ((workingHours - allowance) / 7.00))
                              .ceil();
                          ref
                              .read(targetProvider.notifier)
                              .state = productTarget;
                          productNameController.text = selection.productName;
                          ref.read(focusedProductProvider.notifier).state =
                              selection;
                          await ref
                              .read(lastSelectedProductProvider.notifier)
                              .saveSelectedProduct(
                                selection,
                              );
                          targetController.text = selection.target.toString();
                          focusNodeAutocomplete
                              .unfocus(); // Unfocus using the locally stored focusNode
                        },
                        fieldViewBuilder: (
                          context,
                          textEditingController,
                          // This controller should be used within your TextField
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          focusNodeAutocomplete = focusNode;

                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            // Synchronize text changes with your custom controller if necessary
                            onChanged: (text) {
                              // Update your custom controller if needed
                            },
                            style: TextStyle(
                              color: Colors.orange[100],
                              // Set the color of entered text
                              fontSize: 20,
                              // Set the font size of entered text
                              fontWeight: FontWeight
                                  .bold, // Set the font weight of entered text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Product name',
                              labelStyle: TextStyle(
                                color: Colors.orange[100],
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 18, // Slightly bigger font
                              ),
                              hintText: 'Add product name',
                              hintStyle: TextStyle(
                                color:
                                    Colors.orangeAccent[100]!.withOpacity(0.5),
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 20, // Slightly bigger font
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!
                                      .withOpacity(0.7),
                                  width: 4, // Bolder border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!
                                      .withOpacity(0.5),
                                  width: 4, // Bolder border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!,
                                  width: 4, // Bolder border
                                ),
                              ),
                              suffixIcon: Visibility(
                                visible: focusNodeAutocomplete.hasFocus,
                                child: IconButton(
                                  onPressed: () {
                                    focusNodeAutocomplete.unfocus();
                                  },
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: Colors.orangeAccent[100],
                                        shape: BoxShape.circle,),
                                    child: Icon(
                                      size: 30,
                                      Icons.keyboard_hide,
                                      color: Colors.deepOrange[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: TextField(
                            controller: targetController,
                            focusNode: focusNodeTarget,
                            onChanged: (value) => targetController.text = value,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: Colors
                                  .orange[100], // Set the color of entered text
                              fontSize: 20, // Set the font size of entered text
                              fontWeight: FontWeight
                                  .bold, // Set the font weight of entered text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Target',
                              labelStyle: TextStyle(
                                color: Colors.orange[100],
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 18, // Slightly bigger font
                              ),
                              hintText: 'Add target',
                              hintStyle: TextStyle(
                                color: Colors.orangeAccent[100]!.withOpacity(0.5),
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 20, // Slightly bigger font
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                  Colors.orangeAccent[100]!.withOpacity(0.7),
                                  width: 4, // Bolder border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                  Colors.orangeAccent[100]!.withOpacity(0.5),
                                  width: 4, // Bolder border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!,
                                  width: 4, // Bolder border
                                ),
                              ), // Hint text color
                              suffixIcon: Visibility(
                                visible: targetController.text.isNotEmpty,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.orange[100],
                                  ),
                                  onPressed: () {
                                    targetController.clear();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8,),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.50,
                          child: TextField(
                            focusNode: focusNodeAmount,
                            controller: amountPerBatchController,
                            style: TextStyle(
                              color: Colors
                                  .orange[100], // Set the color of entered text
                              fontSize: 20, // Set the font size of entered text
                              fontWeight: FontWeight
                                  .bold, // Set the font weight of entered text
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount per batch',
                              labelStyle: TextStyle(
                                color: Colors.orange[100],
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 14, // Slightly bigger font
                              ),
                              hintText: 'Enter amount',
                              hintStyle: TextStyle(
                                color:
                                    Colors.orangeAccent[100]!.withOpacity(0.5),
                                fontWeight: FontWeight.bold, // Bold text
                                fontSize: 20, // Slightly bigger font
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!
                                      .withOpacity(0.7),
                                  width: 4, // Bolder border
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orangeAccent[100]!
                                      .withOpacity(0.5),
                                  width: 4, // Bolder border
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.orange[100]!,
                                  width: 4, // Bolder border
                                ),
                              ),
                              suffixIcon: Visibility(
                                visible:
                                    amountPerBatchController.text.isNotEmpty,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.orange[100],
                                  ),
                                  onPressed: () {
                                    amountPerBatchController.clear();
                                  },
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
                        color: Colors.orangeAccent[100],
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
                      physics: const AlwaysScrollableScrollPhysics(),
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
