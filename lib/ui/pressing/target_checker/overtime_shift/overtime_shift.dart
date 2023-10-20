import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/loading_circle_bars.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/basic_shift/slide_to_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/animated_target_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';
import 'slide_to_basicshift.dart';

class OvertimeShift extends ConsumerStatefulWidget {
  const OvertimeShift({Key? key}) : super(key: key);

  @override
  OvertimeShiftCard createState() => OvertimeShiftCard();
}

class OvertimeShiftCard extends ConsumerState<OvertimeShift>
    with TickerProviderStateMixin {
  double overtimeHours = 0.0;
  int overtimeAmount = 0;
  double effectiveWorkingHours = 0.0;

  final TextEditingController overtimeAmountController =
      TextEditingController();
  final TextEditingController overtimeWorkingHoursController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    overtimeAmountController.addListener(_overtimeAmount);
    overtimeWorkingHoursController.addListener(_overtimeWorkingHours);
  }

  void _overtimeAmount() {
    setState(() {
      overtimeAmount = int.tryParse(overtimeAmountController.text) ?? 0;
    });
  }

  void _overtimeWorkingHours() {
    setState(() {
      overtimeHours = double.tryParse(overtimeWorkingHoursController.text) ?? 0;
    });
  }

  @override
  void dispose() {
    overtimeWorkingHoursController.dispose();
    overtimeAmountController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showList = ref.watch(showListProvider);
    final isFocused = ref.watch(focusNotifierProvider);
    final focusNode = ref.read(focusNodeProvider);
    final numberFocusNode = ref.read(numberFocusNodeProvider);
    final allowanceFocusNode = ref.read(allowanceFocusNodeProvider);
    bool isSearchBarFocused = false;

    final TextEditingController textEditingController =
        ref.watch(textEditingControllerProvider);
    final TextEditingController numberController = TextEditingController();
    final allowanceController = TextEditingController();

    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final updated = ref.watch(productUpdateProvider);
    final products = ref.watch(productsProvider(updated));
    final productName =
        ref.watch(selectedProductProvider).state.toLowerCase().trimRight();
    int productTarget = ref.watch(targetProvider);
    final double percentage = ref.watch(targetRatioProvider(userId)) * 100;
    final double targetRatio = ref.watch(targetRatioProvider(userId));
    final int amount = ref.watch(numberProvider);

    double effectiveOvertimeHours = ref
        .read(userNotifierProvider.notifier)
        .calculateEffectiveWorkingHours(overtimeHours);
    double overtimePercents = 0.0;
    if (_overtimeAmount != 0 &&
        productTarget != 0 &&
        effectiveOvertimeHours != 0) {
      overtimePercents = (overtimeAmount / (productTarget)) * 100;
    }

    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;

    final imageNameFuture = ref.watch(imageNameProvider(textEditingController.text));

    return Column(
      children: [
        Stack(children: [
          Column(
            children: [
              Center(child: Container(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.0),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.lightBlue[100]!,
                        Colors.lightBlueAccent,
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
                  ),child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Overtime"),
                  ))),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.82,
                  margin: const EdgeInsets.fromLTRB(20, 10, 10, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.lightBlue[100]!,
                        Colors.lightBlueAccent,
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                                duration: Duration(milliseconds: 400),
                                width: ((isFocused ||
                                        showList ||
                                        productName.isNotEmpty)
                                    ? MediaQuery.of(context).size.width * 0.5
                                    : MediaQuery.of(context).size.width * 0.15),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(33),
                                    color: Colors.yellowAccent[100]),
                                child: TextField(
                                  controller: textEditingController,
                                  textAlign: TextAlign.center,
                                  textAlignVertical: TextAlignVertical.center,
                                  readOnly: overtimeHours ==
                                      0.0, // Make TextField read-only if _overtimeHours is not set
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    suffixIcon: textEditingController
                                                .text.isEmpty &&
                                            !isSearchBarFocused
                                        ? const Center(
                                            child: Icon(Icons.search_rounded))
                                        : IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              setState(() {
                                                ref
                                                    .read(
                                                        searchTermProvider.notifier)
                                                    .state = "";
                                                ref
                                                    .read(selectedProductProvider
                                                        .notifier)
                                                    .state
                                                    .state = "";
                                                textEditingController.clear();
                                                overtimeAmountController.text = '';
                                                ref
                                                    .read(showListProvider.notifier)
                                                    .state = false;
                                                isSearchBarFocused = false;
                                                ref
                                                    .read(showListProvider.notifier)
                                                    .state = false;
                                                FocusScope.of(context)
                                                    .requestFocus(FocusNode());
                                                numberController.clear();

                                                int productTarget =
                                                    ref.read(targetProvider);

                                                ref
                                                    .read(targetProvider.notifier)
                                                    .updateTarget(0);
                                                ref
                                                    .read(
                                                        targetRatioProvider(userId)
                                                            .notifier)
                                                    .init();
                                              });
                                            },
                                          ),
                                    hintStyle: const TextStyle(color: Colors.grey),
                                    hintText: "Search",
                                  ),
                                  onTap: () {
                                    if (overtimeHours == 0.0) {
                                      // If _overtimeHours is not set, show a dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => Dialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  20.0)), //this right here
                                          child: Container(
                                            height: 300,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Center(
                                                    child: Lottie.asset(
                                                        'assets/lottie/alert.json',
                                                        width: 100,
                                                        height:
                                                            100), // Lottie animation
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    'Hey there!',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    'Before you proceed with searching products, please set your overtime hours.',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                  SizedBox(height: 20),
                                                  Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Text('Got it!')),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      if (!showList) {
                                        setState(() {
                                          ref
                                              .read(showListProvider.notifier)
                                              .state = true;
                                          isSearchBarFocused = true;

                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                          numberController.clear();
                                        });
                                      }
                                    }
                                  },
                                  onChanged: (value) {
                                    ref.read(searchTermProvider.notifier).state =
                                        value;
                                    ref
                                        .read(selectedProductProvider.notifier)
                                        .state
                                        .state = value;
                                  },
                                  onSubmitted: (value) {
                                    setState(() {
                                      ref.read(showListProvider.notifier).state =
                                          false;
                                    });
                                  },
                                )),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            width: ((isFocused || showList)
                                ? MediaQuery.of(context).size.width * 0.15
                                : MediaQuery.of(context).size.width * 0.25),
                            child: TextFormField(
                              onChanged: (value) {
                                ref
                                    .watch(overtimeWorkingHoursState.notifier)
                                    .state = int.tryParse(value);
                              },
                              controller: overtimeWorkingHoursController,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                labelText: 'Hours',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 1.0,
                                ),
                                fillColor: Colors.yellowAccent[100],
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(33),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.timer),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false, signed: false),
                              enabled: ((productName != '' || isSearchBarFocused)
                                  ? false
                                  : true), // disable TextField when productName is empty
                            ),
                          ),
                        ],
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
                                    .where((product) => product.name
                                        .toLowerCase()
                                        .contains(ref
                                            .watch(searchTermProvider)
                                            .toLowerCase()))
                                    .toList();
                                return ListView.builder(
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = filteredProducts[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(33),
                                        color: Colors.white,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      child: ListTile(
                                        title: Text(product.name),
                                        subtitle: Text(
                                            'Target: ${((product.target.toDouble() ?? 0) * (effectiveOvertimeHours / 7.00)).ceil()}'),
                                        onTap: () {
                                          String selectedProductName = product.name;
                                          ref
                                              .watch(
                                                  selectedProductProvider.notifier)
                                              .state
                                              .state = selectedProductName;
                                          textEditingController.text =
                                              selectedProductName
                                                  .toString(); // Update the controller's text
                                          ref
                                              .read(showListProvider.notifier)
                                              .state = false;
                                          ref
                                              .read(focusNodeProvider)
                                              .requestFocus();

                                          // Update the targetProvider state when a product is selected
                                          int productTarget = (((product.target
                                                      .toDouble()) *
                                                  ((effectiveOvertimeHours) / 7.00))
                                              .ceil());
                                          ref
                                              .read(targetProvider.notifier)
                                              .updateTarget(productTarget);
                                          overtimeAmountController.text = '';
                                        },
                                      ),
                                    );
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
                        imageNameFuture.when(
                          data: (imageName) {
                            print("Image Name: $imageName");
                            if (imageName != null) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width * 0.66,
                                height: MediaQuery.of(context).size.width * 0.66,
                                child: Image.asset(
                                  'assets/images/$imageName.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                    print("Image Error: $exception");
                                    return Lottie.asset('assets/lottie/product_image_not_found.json');
                                  },
                                ),
                              );
                            } else {
                              return Lottie.asset(
                                  'assets/lottie/product_image_not_found.json');
                            }
                          },
                          loading: () => CircularProgressIndicator(),
                          error: (error, stack) => Lottie.asset(
                              'assets/lottie/product_image_not_found.json'),
                        ),
                      if (!showList && productName == "")
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.blue[100]!,
                                Colors.blue[200]!,
                                Colors.blue[300]!,
                                Colors.blue[400]!,
                                Colors.black,
                              ],
                              stops: [
                                0.0,
                                0.3,
                                0.5,
                                0.7,
                                1.0
                              ], // controls the color transition positions
                              center: Alignment(-0.5,
                                  -0.5), // shift the center alignment to mimic light reflection
                              radius:
                                  1.5, // controls the overall radius of the gradient
                              focal: Alignment(-0.5,
                                  -0.5), // controls the focal point of the gradient
                              focalRadius:
                                  0.1, // controls the radius of the focal point
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 12,
                                offset: Offset(4, 4), // changes position of shadow
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontSize: 75,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                      if (!showList)
                        Form(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                            child: Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.40,
                                child: TextFormField(
                                  controller: overtimeAmountController,
                                  textAlign: TextAlign.center,
                                  // Center the text
                                  decoration: InputDecoration(
                                    alignLabelWithHint: true,
                                    labelText: 'Amount',
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
                                    prefixIcon: const Icon(Icons
                                        .numbers_outlined), // Add an icon symbolizing number input here
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
                                    ref.read(overtimeRatioProvider.notifier).state =
                                        (overtimeAmount / productTarget);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!showList)
                        Row(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Stack(
                                children: [
                                  Center(
                                    child: Transform.scale(
                                      scale: 4.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 10.0,
                                        // Divide by the scale factor
                                        backgroundColor:
                                            Colors.greenAccent.shade100,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.transparent),
                                        value: 1.0,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Transform.scale(
                                      scale: 4.0,
                                      child: MinimumCircle(
                                        percentage: overtimePercents,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Transform.scale(
                                      scale: 4.0,
                                      child: ClipOval(
                                        child: RainbowCircularProgressIndicator(
                                          percentage:
                                              overtimePercents, // Substitute your actual percentage here
                                        ),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Container(
                                      width: 105,
                                      height: 105,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.green.shade50,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Consumer(
                                      builder: (context, watch, _) {
                                        return Text(
                                          '${(overtimePercents).toStringAsFixed(2)}%',
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
                              child: Column(children: [
                                TargetButton(
                                    productName: productName, overtimes: true),
                                Padding(
                                  padding: const EdgeInsets.only(right: 3.0),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child:
                                        Consumer(builder: (context, watch, child) {
                                      final userState = ref
                                          .watch(userNotifierProvider.notifier)
                                          .state;
                                      final bonus = ref.watch(bonusValueProvider(
                                          overtimePercents / 100));
                                      final allowance = userState.allowance;

                                      return BonusCoin(
                                          bonus: bonus * (overtimeHours / 7.00));
                                    }),
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      //add a new widget to the row
                      if (!showList)
                        Builder(
                          builder: (BuildContext buttonContext) {
                            return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: LayoutBuilder(builder: (BuildContext context,
                                    BoxConstraints constraints) {
                                  return SizedBox(
                                    // 10
                                    width: constraints.maxWidth *
                                        0.6, // % of the Container height
                                    // 10% of the Container height
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
                                              overtimeAmount == 0 ||
                                              overtimeHours == 0)
                                          ? null
                                          : () async {
                                              final authRepository =
                                                  ref.read(authRepositoryProvider);
                                              final pressingRepository = ref
                                                  .read(pressingRepositoryProvider);
                                              print(overtimePercents);
                                              final bonusChecker = ref.read(
                                                  bonusValueProvider(
                                                      overtimePercents / 100));
                                              final double bonus = bonusChecker *
                                                  (overtimeHours / 7);
                                              final String userId =
                                                  authRepository.currentUserId;
                                              final String productName = ref
                                                  .read(selectedProductProvider)
                                                  .state;
                                              final productRatioProvider = ref.read(
                                                  targetRatioProvider(userId)
                                                      .notifier);
                                              final double productRatio =
                                                  productRatioProvider
                                                      .getProductRatio(productName);
                                              print(productRatio);
                                              // Retrieve the bonus value

                                              try {
                                                await pressingRepository
                                                    .saveOvertimeUserBonus(
                                                        userId,
                                                        productName,
                                                        bonus,
                                                        overtimeAmount,
                                                        overtimePercents / 100,
                                                        isOvertime: true,
                                                        workingHours: userState
                                                                    .paidBreaks ??
                                                                false
                                                            ? overtimeHours
                                                            : effectiveOvertimeHours);
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
                                              ref
                                                  .read(targetRatioProvider(userId)
                                                      .notifier)
                                                  .init();

                                              // Show a success message or navigate to another screen
                                            },
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        // Center the content horizontally
                                        children: [
                                          Icon(Icons.wallet),
                                          // Add your desired icon
                                          SizedBox(width: 8),
                                          // Add some space between the icon and the text
                                          Text('Save to Wallet'),
                                        ],
                                      ),
                                    ),
                                  );
                                }));
                          },
                        ),
                      SlideToBasicShift(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
