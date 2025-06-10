import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/amount_calculator_field.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/product_description.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/custom_save_button.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/autocomplete_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/last_selected_products.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/search_bar.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/not_selected_product_sphere.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/rive_ellipses.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/rive_target_animation.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

class BasicShift extends ConsumerStatefulWidget {
  const BasicShift({ super.key});


  @override
  BasicShiftCard createState() => BasicShiftCard();
}

class BasicShiftCard extends ConsumerState<BasicShift>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final focusedProduct = ref.watch(focusedProductProvider);
      final allowance = ref.watch(allowanceProvider);
      final userState = ref.watch(userNotifierProvider);
      final workingHours = userState.workingHours ?? 0.0;

      final numberController =
          ref.watch(numberControllerProvider.notifier).controller;
      ref
          .read(
            bonusInfoListProvider.notifier,
          )
          .updateRatio(
            focusedProduct.productName.toLowerCase().trimRight(),
            ref.read(targetProvider),
            int.tryParse(numberController.text) ?? 0,
            workingHours,
            allowance,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final showList = ref.watch(showListProvider);
    final numberFocusNode = ref.watch(numberFocusNodeProvider);
    final allowanceFocusNode = ref.watch(allowanceFocusNodeProvider);
    final targetRatio = ref.watch(bonusInfoListProvider).ratio;

    final userState = ref.watch(userNotifierProvider);
    final allowance = ref.watch(allowanceProvider);
    final workingHours = userState.workingHours ?? 0.0;

    final numberController =
        ref.watch(numberControllerProvider.notifier).controller;
    final allowanceController = ref.read(allowanceControllerProvider);
    final focusedProduct = ref.watch(focusedProductProvider);

    return GestureDetector(
      onTap: () {
        numberFocusNode.unfocus();
        allowanceFocusNode.unfocus();
        ref.read(showListProvider.notifier).state = false;
        ref.read(focusNodeProvider).unfocus();
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
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(3, 6),
              blurRadius: 10,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
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
            ),
            if (showList) _buildProductList(ref),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!showList)
                  if (focusedProduct.imageName != 'question')
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
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
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(iconSize: 32,
                            icon: const Icon(Icons.info_outline),
                            onPressed: () async => showProductNoteDialog(context, ref),
                          ),
                        ),
                      ],
                    )
                  else
                    const SphereQuestionMark(),
              ],
            ),
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
                        child: CalculatorField(
                          allowance: allowance,
                          controller: numberController,
                          focusNode: numberFocusNode,
                          focusedProductName: focusedProduct.productName,
                          ref: ref,
                          workingHours: workingHours,
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
                              hintText: 'Allowance',
                              labelText: (allowance * 60).toInt() == 0
                                  ? 'Allowance'
                                  : targetRatio <= 0
                                      ? 'Allowance'
                                      : '${(allowance * 60).toInt()}-Allowance ',
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
                              ref
                                  .read(allowanceProvider.notifier)
                                  .updateAllowance(allowanceProvided);
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
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Divider(
                                    indent: 35,
                                    endIndent: 35,
                                    thickness: 2,
                                    height: 20,
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
                                        '£ ${formatDouble(bonus)}',
                                        style: TextStyle(
                                          color: Colors.green[900],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
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
            const SizedBox(height: 16,),
            // const SlideToOvertime(),
          ],
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
