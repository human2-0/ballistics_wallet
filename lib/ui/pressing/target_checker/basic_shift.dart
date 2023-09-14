import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/circles.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/slide_to_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/target_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/utilities.dart';

import '../../../providers/pressing_provider.dart';

class BasicShift extends ConsumerStatefulWidget {
  const BasicShift({Key? key}) : super(key: key);

  @override
  BasicShiftCard createState() => BasicShiftCard();
}

class BasicShiftCard extends ConsumerState<BasicShift>
    with TickerProviderStateMixin {





  @override
  Widget build(BuildContext context) {
    final showList = ref.watch(showListProvider);
    final focusNode = ref.watch(focusNodeProvider);
    final numberFocusNode = ref.watch(numberFocusNodeProvider);
    final allowanceFocusNode = ref.watch(allowanceFocusNodeProvider);
    bool isSearchBarFocused = false;


    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final updated = ref.watch(productUpdateProvider);
    final products = ref.watch(productsProvider(updated));
    final productName =
        ref.watch(selectedProductProvider).state.toLowerCase().trimRight();
    int productTarget = ref.watch(targetProvider);
    final double percentage = ref.watch(targetRatioProvider(userId)) * 100;
    final double targetRatio = ref.watch(targetRatioProvider(userId));
    final int amount = ref.watch(numberProvider);

    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;

    final textEditingController = ref.watch(textEditingControllerProvider);
    final numberController = ref.watch(numberControllerProvider);
    final allowanceController = ref.watch(allowanceControllerProvider);


    return GestureDetector(
      onTap: () {
        numberFocusNode.unfocus();
        allowanceFocusNode.unfocus();
        ref.read(showListProvider.notifier).state = false;
        focusNode.unfocus();
      },
      child: Stack(children: [
        Center(
          child: Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.82,
                margin: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange[50]!,
                      Colors.orange[100]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[100]!,
                              Colors.orange[200]!,
                              Colors.orange[300]!,
                            ],
                            stops: [
                              0.0,
                              0.5,
                              0.9,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        duration: const Duration(milliseconds: 400),
                        width: ((showList || focusNode.hasFocus || (textEditingController.text != ""))
                            ? MediaQuery.of(context).size.width * 0.66
                            : MediaQuery.of(context).size.width * 0.12),
                        child: TextField(
                          focusNode: focusNode,
                          controller: textEditingController,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixIcon: textEditingController.text.isEmpty
                                ? const Icon(Icons.search_rounded)
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      ref
                                          .read(searchTermProvider.notifier)
                                          .state = "";
                                      ref
                                          .read(
                                              selectedProductProvider.notifier)
                                          .state
                                          .state = "";
                                      textEditingController.clear();
                                      ref
                                          .read(showListProvider.notifier)
                                          .state = false;
                                      ref
                                          .read(focusNodeProvider).unfocus();
                                      focusNode.unfocus();
                                      isSearchBarFocused = false;
                                      numberController.clear();

                                      int productTarget =
                                          ref.read(targetProvider);

                                      ref
                                          .read(targetProvider.notifier)
                                          .updateTarget(0);
                                      ref
                                          .read(allowanceProvider.notifier)
                                          .state = 0.0;
                                      ref
                                          .read(targetRatioProvider(userId)
                                              .notifier)
                                          .init();
                                      ref.read(numberProvider.notifier).state = 0 ;
                                    },
                                  ),
                            hintStyle: const TextStyle(color: Colors.grey),
                            hintText: "Search",
                          ),
                          onTap: () {
                            if (!showList) {
                              ref.read(showListProvider.notifier).state = true;
                              isSearchBarFocused = true;

                              FocusScope.of(context).requestFocus(FocusNode());
                              numberController.clear();
                            }
                          },
                          onChanged: (value) {
                            ref.read(searchTermProvider.notifier).state = value;
                            ref
                                .read(selectedProductProvider.notifier)
                                .state
                                .state = value;
                          },
                          onSubmitted: (value) {
                            ref.read(showListProvider.notifier).state = false;
                          },
                        ),
                      ),
                    ),
                    if (showList)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(33),
                            ),
                            color: Colors.orange[50],
                          ),
                          child: products.when(
                            data: (data) {
                              final filteredProducts = data
                                  .where((product) => product['name']
                                      .toLowerCase()
                                      .contains(ref
                                          .watch(searchTermProvider)
                                          .toLowerCase()))
                                  .toList();
                              return ListView.builder(
                                itemCount: filteredProducts.isEmpty
                                    ? 1
                                    : filteredProducts.length,
                                itemBuilder: (context, index) {
                                  if (filteredProducts.isEmpty) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(33),
                                        color: Colors.white,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      child: ListTile(
                                        title: const Text(
                                            'Not found what you\'re looking for?'),
                                        trailing: Container(
                                          padding:
                                              const EdgeInsets.fromLTRB(4, 8, 4, 8),
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 16,
                                                offset: const Offset(4,
                                                    4), // changes position of shadow
                                              ),
                                            ],
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.orange[50]!,
                                                Colors.orange[200]!,
                                                Colors.orange[300]!,
                                              ],
                                              stops: [
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
                                                final productNameController =
                                                    TextEditingController();
                                                final targetController =
                                                    TextEditingController();

                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Dialog(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(16),
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.35,
                                                          // 30% of screen height
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.80,
                                                          // 75% of screen width
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: <Widget>[
                                                              const Text(
                                                                  "Add a new product"),
                                                              TextField(
                                                                controller:
                                                                    productNameController,
                                                                decoration:
                                                                    const InputDecoration(
                                                                        labelText:
                                                                            'Product Name'),
                                                              ),
                                                              TextField(
                                                                controller:
                                                                    targetController,
                                                                decoration:
                                                                    const InputDecoration(
                                                                        labelText:
                                                                            'Target'),
                                                                keyboardType:
                                                                    TextInputType
                                                                        .number,
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                children: [
                                                                  TextButton(
                                                                    child: const Text(
                                                                        'Cancel'),
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                  ),
                                                                  TextButton(
                                                                    child: const Text(
                                                                        'Add'),
                                                                    onPressed:
                                                                        () async {
                                                                      final String
                                                                          productName =
                                                                          productNameController
                                                                              .text;
                                                                      final String
                                                                          targetString =
                                                                          targetController
                                                                              .text;

                                                                      if (productName
                                                                          .isEmpty) {
                                                                        return;
                                                                      }

                                                                      final int?
                                                                          target =
                                                                          int.tryParse(
                                                                              targetString);
                                                                      if (target ==
                                                                          null) {
                                                                        return;
                                                                      }

                                                                      try {
                                                                        await ref
                                                                            .read(
                                                                                pressingRepositoryProvider)
                                                                            .addProduct(
                                                                                productName,
                                                                                target);
                                                                        ref
                                                                            .read(
                                                                                productUpdateProvider.notifier)
                                                                            .update();
                                                                        Navigator.of(
                                                                                context)
                                                                            .pop();
                                                                      } catch (e) {
                                                                      }
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    });
                                              }),
                                        ),
                                      ),
                                    );
                                  }
// If the index is not 0, adjust it by 1 to get the correct product
                                  else {
                                    final product = filteredProducts[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(33),
                                        color: Colors.white,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      child: ListTile(
                                        title: Text(product['name']),
                                        subtitle: Text(
                                            'Target: ${((product['target']?.toDouble() ?? 0) * ((workingHours - allowance) / 7.00)).ceil()}'),
                                        onTap: () {
                                          String selectedProductName =
                                              product['name'];
                                          ref
                                              .watch(selectedProductProvider
                                                  .notifier)
                                              .state
                                              .state = selectedProductName;
                                          textEditingController.text =
                                              selectedProductName
                                                  .toString(); // Update the controller's text
                                          ref
                                              .read(showListProvider.notifier)
                                              .state = false;
                                          ref
                                              .read(focusNodeProvider).unfocus();

// Update the targetProvider state when a product is selected
                                          int productTarget = (((product['target']
                                                      ?.toDouble()) *
                                                  ((workingHours - allowance) /
                                                      7.00))
                                              .ceil());
                                          ref
                                              .read(targetProvider.notifier)
                                              .updateTarget(productTarget);
                                        },
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (error, stackTrace) => Text('Error: $error'),
                          ),
                        ),
                      ),
                    if (!showList && productName != '')
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.66,
                        height: MediaQuery.of(context).size.width * 0.66,
                        child: Image.asset(
                          'assets/images/${ref.read(pressingRepositoryProvider).getImageNameForProduct(productName)}.png',
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception,
                              StackTrace? stackTrace) {
// If the image fails to load, load a Lottie animation
                            return Lottie.asset(
                                'assets/lottie/product_image_not_found.json');
                          },
                        ),
                      ),
                    if (!showList && productName == "")
                      Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.orange[100]!,
                              Colors.orange[200]!,
                              Colors.orange[300]!,
                              Colors.orange[400]!,
                              Colors.black,
                            ],
                            stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                            // controls the color transition positions
                            center: const Alignment(-0.5, -0.5),
                            // shift the center alignment to mimic light reflection
                            radius: 1.5,
                            // controls the overall radius of the gradient
                            focal: const Alignment(-0.5, -0.5),
                            // controls the focal point of the gradient
                            focalRadius:
                                0.1, // controls the radius of the focal point
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 5,
                              blurRadius: 12,
                              offset: const Offset(4, 4), // changes position of shadow
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: 75,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    if (!showList)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.43,
                              child: TextFormField(
                                focusNode: numberFocusNode,
                                controller: numberController,
                                textAlign: TextAlign.center,
// Center the text
                                decoration: InputDecoration(
                                  alignLabelWithHint: true,
                                  labelText: 'Amount pressed',
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  fillColor: Colors.yellowAccent[100],
// Add the color of the search bar widget here
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(33),
// Rounded edges
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.numbers_outlined),
                                  suffixIcon: Visibility(
                                    visible: numberFocusNode.hasFocus,
                                    child: IconButton(
                                      icon: const Icon(Icons.keyboard_hide),
                                      onPressed: () {
                                        numberFocusNode.unfocus();
                                      },
                                    ),
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: false, signed: false),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  int parsedValue = int.tryParse(value) ?? 0;
                                  ref
                                      .read(numberProvider.notifier)
                                      .updateNumber(parsedValue);

                                  ref
                                      .read(
                                          targetRatioProvider(userId).notifier)
                                      .updateRatio(productName, productTarget,
                                          parsedValue, workingHours, allowance);
                                },
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.40,
                                child: TextFormField(
                                  focusNode: allowanceFocusNode,
                                  controller: allowanceController,
                                  decoration: InputDecoration(
                                    alignLabelWithHint: true,
                                    labelText: 'Allowance',
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    fillColor: Colors.yellowAccent[100],
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(33),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.timer),
                                    suffixIcon: Visibility(
                                      visible: allowanceFocusNode.hasFocus,
                                      child: IconButton(
                                        icon: const Icon(Icons.keyboard_hide),
                                        onPressed: () {
                                          allowanceFocusNode.unfocus();
                                        },
                                      ),
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: false, signed: false),
                                  onChanged: (value) {
                                    int parsedValue = int.tryParse(value) ?? 0;
                                    double allowanceProvided = parsedValue == 0
                                        ? 0.0
                                        : parsedValue / 60;
                                    ref.read(allowanceProvider.notifier).state =
                                        allowanceProvided;

// allowanceController.text = value; // Remove this line

                                    int declaredAmount =
                                        ref.read(numberProvider);
                                    ref
                                        .read(targetRatioProvider(userId)
                                            .notifier)
                                        .updateRatio(
                                          productName.toLowerCase(),
                                          productTarget,
                                          declaredAmount,
                                          workingHours,
                                          allowanceProvided,
                                        );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!showList)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.50,
                            height: MediaQuery.sizeOf(context).height * 0.20,
                            child: Stack(
                              children: [
                                Center(
                                  child: Transform.scale(
                                    scale: 4.0,
                                    child: MinimumCircle(
                                      percentage: percentage,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Transform.scale(
                                    scale: 4.5,
                                      child: RainbowCircularProgressIndicator(
                                        percentage:
                                            percentage, // Substitute your actual percentage here
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    width: 105,
                                    height: 105,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange[50]!,
                                          Colors.orange[200]!
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Consumer(
                                    builder: (context, watch, _) {
                                      return Text(
                                        '${(targetRatio * 100).toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                TargetButton(productName: productName),
                                Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Consumer(
                                        builder: (context, watch, child) {
                                      final userState = ref
                                          .watch(userNotifierProvider.notifier)
                                          .state;
                                      final bonus = ref
                                          .watch(bonusValueProvider(targetRatio)) *  ((workingHours - (allowance)) /
                                          7.00);
                                      return BonusCoin(
                                          bonus: bonus);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
//add a new widget to the row
                    if (!showList)
                      Builder(
                        builder: (BuildContext buttonContext) {
                          return LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: constraints.maxWidth *
                                      0.60,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(
                                          Colors.yellowAccent[100]),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                    onPressed: (productName.isEmpty ||
                                            amount == 0)
                                        ? null
                                        : () async {
                                            final authRepository =
                                                ref.read(authRepositoryProvider);
                                            final pressingRepository = ref
                                                .read(pressingRepositoryProvider);
                                            final bonusAsyncValue = ref.read(
                                                bonusValueProvider(
                                                    targetRatio)); // changed watch to read
                                            final String userId =
                                                authRepository.currentUserId;
                                            final String productName = ref
                                                .read(selectedProductProvider)
                                                .state;
                                            double bonus = bonusAsyncValue *
                                                ((workingHours - allowance) /
                                                    7.0);
                                            final productRatioProvider = ref.read(
                                                targetRatioProvider(userId)
                                                    .notifier);
                                            final double productRatio =
                                                productRatioProvider
                                                    .getProductRatio(productName);
// Retrieve the bonus value

                                            try {
                                              await pressingRepository.saveUserBonus(
                                                  userId,
                                                  productName,
                                                  bonus,
                                                  amount,
                                                  productRatio,
                                                  workingHours: (userState
                                                              .paidBreaks ??
                                                          false)
                                                      ? (userState
                                                              .realWorkingHours ??
                                                          0)
                                                      : (userState.workingHours ??
                                                          0));
// Show a success message
                                              ScaffoldMessenger.of(buttonContext)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Saved to Wallet successfully!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              if (e is String) {
                                                ref
                                                    .read(targetRatioProvider(
                                                            userId)
                                                        .notifier)
                                                    .init();
// Handle the case where the bonus is already added today
                                                ScaffoldMessenger.of(
                                                        buttonContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'This product has been overwritten because it was already added today.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.orange,
                                                  ),
                                                );
// Call editUserBonus if saveUserBonus fails
                                                await pressingRepository
                                                    .editUserBonus(
                                                  e,
// Pass the bonusId as the first parameter
                                                  productName,
                                                  bonus,
                                                  amount,
                                                );
                                              } else {
// Show an error message for other exceptions
                                                ScaffoldMessenger.of(
                                                        buttonContext)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(e.toString()),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }

// Show a success message or navigate to another screen
                                          },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
// Center the content horizontally
                                      children: [
                                        Icon(Icons.wallet),
                                        SizedBox(width: 8),

// Add your desired icon
// Add some space between the icon and the text
                                        Text('Save to Wallet'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SlideToOvertime(),
                              ],
                            );
                          });
                        },
                      ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
