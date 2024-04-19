import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/basic_shift/slide_to_overtimes.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/custom_save_button.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/autocomplete_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/last_selected_products.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/search_bar.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/not_selected_product_sphere.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/rive_ellipses.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/rive_target_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class BasicShift extends ConsumerStatefulWidget {
  const BasicShift({required this.onNotification, super.key});
  final void Function(ScrollNotification) onNotification;

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

    final productTarget = ref.watch(targetProvider);
    final targetRatio = ref.watch(bonusInfoListProvider).ratio;

    final userState = ref.watch(userNotifierProvider);
    final allowance = ref.watch(allowanceProvider);
    final workingHours = userState.workingHours ?? 0.0;

    final numberController =
        ref.read(numberControllerProvider.notifier).controller;
    final allowanceController =
        ref.read(allowanceControllerProvider.notifier).controller;
    final focusedProduct = ref.watch(focusedProductProvider);
    print(focusedProduct.imageName);

    return GestureDetector(
      onTap: () {
        numberFocusNode.unfocus();
        allowanceFocusNode.unfocus();
        ref.read(showListProvider.notifier).state = false;
        focusNode.unfocus();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          widget.onNotification(notification);
          return true;
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.83,
          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(66),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[100]!.withOpacity(0.80),
                Colors.orange[200]!.withOpacity(0.80),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                offset: const Offset(3, 6),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                offset: const Offset(-3, -6),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SearchProductBar(
                numberController: numberController,
                focusNode: focusNode,
              ),
              if (showList) _buildProductList(ref),
              if (!showList)
                if (focusedProduct.imageName != 'question')
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: MediaQuery.of(context).size.width * 0.55,
                    child: Image.asset(
                      'assets/images/${focusedProduct.imageName}.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, exception, stackTrace) =>
                          Lottie.asset(
                        'assets/lottie/product_image_not_found.json',
                      ),
                    ),
                  )
                else
                  const SphereQuestionMark(), // Assuming SphereQuestionMark is a widget you've defined
              if (!showList)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.43,
                        child: DecoratedBox(
                          decoration: boxDecoration(),
                          child: TextFormField(
                            focusNode: numberFocusNode,
                            controller: numberController,
                            textAlign: TextAlign.center,
                            // Center the text
                            decoration: InputDecoration(
                              alignLabelWithHint: true,
                              labelText: 'Amount pressed',
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              fillColor: Colors.yellowAccent[100],
                              // Add the color of the search bar widget here
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(33),
                                // Rounded edges
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              suffixIcon: Visibility(
                                visible: numberFocusNode.hasFocus,
                                child: IconButton(
                                  icon: const Icon(Icons.keyboard_hide),
                                  onPressed: numberFocusNode.unfocus,
                                ),
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a number';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              ref
                                  .read(
                                    bonusInfoListProvider.notifier,
                                  )
                                  .updateRatio(
                                    focusedProduct.productName.toLowerCase(),
                                    productTarget,
                                    int.tryParse(value) ?? 0,
                                    workingHours,
                                    allowance,
                                  );
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Check if the allowance field is disabled
                          if (targetRatio >= 0) {
                            // Show a SnackBar or other user feedback mechanism
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please set the allowance before adding anything to wallet.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: DecoratedBox(
                            decoration: boxDecoration(),
                            child: TextFormField(
                              enabled: targetRatio <= 0,
                              focusNode: allowanceFocusNode,
                              controller: allowanceController,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                labelText: 'Allowance',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                                    onPressed: allowanceFocusNode.unfocus,
                                  ),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (value) {
                                final parsedValue = int.tryParse(value) ?? 0;
                                final allowanceProvided =
                                    parsedValue == 0 ? 0.0 : parsedValue / 60;
                                ref.read(allowanceProvider.notifier).state =
                                    allowanceProvided;

                                ref
                                    .read(
                                      bonusInfoListProvider.notifier,
                                    )
                                    .updateRatio(
                                      focusedProduct.productName
                                          .toLowerCase()
                                          .trimRight(),
                                      productTarget,
                                      int.tryParse(numberController.text) ?? 0,
                                      workingHours,
                                      allowanceProvided,
                                    );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!showList)
                Stack(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: MediaQuery.of(context).size.height * 0.28,
                          child: Stack(
                            children: [
                              Positioned(
                                child: Center(
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 0.25,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange[50]!,
                                          Colors.orange[200]!,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: 1.5,
                                child: const RiveEllipses(),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '% ${(targetRatio * 100).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Divider(
                                      indent: 40,
                                      endIndent: 40,
                                      thickness: 2,
                                      height: 24,
                                    ),
                                    Consumer(
                                      builder: (context, watch, child) {
                                        final bonus = ref.watch(
                                              bonusCalculator(
                                                targetRatio,
                                              ),
                                            ) *
                                            ((workingHours - allowance) / 7.00);
                                        return Text(
                                          '£ ${bonus.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 54,
                      left: -64,
                      child: Transform.scale(
                        scale: 1.3,
                        child: TargetBoard(
                          productName: focusedProduct.productName,
                        ),
                      ),
                    ),
                  ],
                ),

              //add a new widget to the row
              if (!showList) const CustomSaveButton(),
              const SlideToOvertime(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(WidgetRef ref) {
    // Watch the current search term
    final productNameController = ref.watch(productNameControllerProvider);
    final products = ref.watch(lastSelectedProductProvider);
    if (productNameController.isEmpty && products.isNotEmpty) {
      return const LastSelectedProducts();
    } else {
      return const ProductsListSuggested();
    }
  }
}
