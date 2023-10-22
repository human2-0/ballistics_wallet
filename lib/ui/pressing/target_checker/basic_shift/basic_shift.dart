import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/loading_circle_bars.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/not_selected_product_sphere.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/products_list_suggested.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/animated_target_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';
import '../custom_save_button.dart';
import '../look_up_bar/last_selected_products.dart';
import '../look_up_bar/search_bar.dart';

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

    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final productName =
        ref.watch(selectedProductProvider).state.toLowerCase().trimRight();
    print("here is what i pass $productName");

    int productTarget = ref.watch(targetProvider);
    final double percentage = ref.watch(targetRatioProvider(userId)) * 100;
    final double targetRatio = ref.watch(targetRatioProvider(userId));

    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;

    final textEditingController = ref.watch(textEditingControllerProvider);
    final numberController = ref.watch(numberControllerProvider);
    final allowanceController = ref.watch(allowanceControllerProvider);

    final imageNameFuture =
        ref.watch(imageNameProvider(textEditingController.text));

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
                    SearchProductBar(
                      textEditingController: textEditingController,
                      numberController: numberController,
                      focusNode: focusNode,
                    ),
                    if (showList) _buildProductList(ref),
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
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  print("Image Error: $exception");
                                  return Lottie.asset(
                                      'assets/lottie/product_image_not_found.json');
                                },
                              ),
                            );
                          } else {
                            return Lottie.asset(
                                'assets/lottie/product_image_not_found.json');
                          }
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Lottie.asset(
                            'assets/lottie/product_image_not_found.json'),
                      ),
                    if (!showList && productName == "")
                      const SphereQuestionMark(),
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
                                      final bonus = ref.watch(
                                              bonusValueProvider(targetRatio)) *
                                          ((workingHours - (allowance)) / 7.00);
                                      return BonusCoin(bonus: bonus);
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
//add a new widget to the row
                    if (!showList) const CustomSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildProductList(WidgetRef ref) {
    // Watch the state of our SelectedProductNotifier
    final selectedProducts = ref.watch(lastSelectedProductProvider);

    // Watch the current search term
    final currentSearchTerm = ref.watch(searchTermProvider);

    // Check if the search term is empty
    final textIsEmpty = currentSearchTerm.isEmpty;

    // If the text is empty and there are recent products, show LastSelectedProducts
    if (textIsEmpty && selectedProducts.isNotEmpty) {
      return LastSelectedProducts();
    } else {
      return const ProductsListSuggested();
    }
  }


}
