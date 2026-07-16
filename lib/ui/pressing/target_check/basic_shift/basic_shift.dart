import 'dart:async';
import 'dart:math' as math;

import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/product_image_view.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/product_weight_summary.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/amount_calculator_field.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/basic_shift/product_description.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/custom_save_button.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/autocomplete_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/edit_weight_range.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/last_selected_products.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/not_selected_product_sphere.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/rive_ellipses.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/rive_target_animation.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

/// Main basic-shift target checking card.
class BasicShift extends ConsumerStatefulWidget {
  /// Creates the basic-shift target checking card.
  const BasicShift({super.key});

  @override
  BasicShiftCard createState() => BasicShiftCard();
}

/// State for the basic-shift target checking card.
class BasicShiftCard extends ConsumerState<BasicShift>
    with TickerProviderStateMixin {
  Timer? _allowancePersistenceDebounce;

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
          .read(bonusInfoListProvider.notifier)
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
  void dispose() {
    _allowancePersistenceDebounce?.cancel();
    super.dispose();
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
    final hasSelectedProduct = focusedProduct.productName.trim().isNotEmpty;
    final allowanceMinutes = (allowance * 60).round();
    if (!allowanceFocusNode.hasFocus &&
        allowanceMinutes > 0 &&
        allowanceController.text != allowanceMinutes.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || allowanceFocusNode.hasFocus) return;
        final text = allowanceMinutes.toString();
        allowanceController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });
    }
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final bottomNavigationSpace = (screenSize.height * 0.08) + 22;
    final availableCardHeight =
        screenSize.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        bottomNavigationSpace;
    // Search is a separate 64px glass surface above this card. Subtracting it
    // keeps the combined target-check layout within the previous height budget.
    final cardHeight = (availableCardHeight - 64).clamp(496.0, 656.0);
    final cardWidth = screenSize.width * 0.95;
    final fieldWidth = cardWidth * 0.46;
    final productImageSize = math.min(
      screenSize.width * 0.48,
      cardWidth * 0.58,
    );
    final weightBadgeWidth = math.min(cardWidth * 0.34, 150).toDouble();

    return GestureDetector(
      onTap: () {
        dismissTargetCheckInputs(ref);
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(66),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[50]!, Colors.orange[100]!],
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
            if (showList) _buildProductList(ref),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!showList)
                  if (focusedProduct.imageName != 'question')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            SizedBox(
                              width: productImageSize,
                              height: productImageSize,
                              child: ProductImagePreview(
                                imageName: focusedProduct.imageName,
                                productName: focusedProduct.productName,
                                scale: focusedProduct.imageScale,
                                offsetX: focusedProduct.imageOffsetX,
                                offsetY: focusedProduct.imageOffsetY,
                                fallbackBuilder:
                                    (context) => Lottie.asset(
                                      'assets/lottie/product_image_not_found.json',
                                    ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                iconSize: 32,
                                icon: const Icon(Icons.info_outline),
                                onPressed:
                                    () => showProductNoteDialog(context, ref),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: weightBadgeWidth,
                          child: ProductWeightSummary(
                            weightGrams: focusedProduct.finalProductWeightGrams,
                            hasFormula: focusedProduct.hasWeightFormula,
                            customMinGrams:
                                focusedProduct.customWeightRangeMinGrams,
                            customMaxGrams:
                                focusedProduct.customWeightRangeMaxGrams,
                            onLongPress:
                                () => showEditWeightRangeDialog(
                                  context,
                                  ref,
                                  product: focusedProduct,
                                ),
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
                  mainAxisAlignment:
                      hasSelectedProduct
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.center,
                  children: [
                    if (hasSelectedProduct)
                      SizedBox(
                        width: fieldWidth,
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
                    SizedBox(
                      width: fieldWidth,
                      child: DecoratedBox(
                        decoration: boxDecoration(),
                        child: TextFormField(
                          focusNode: allowanceFocusNode,
                          controller: allowanceController,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            hintText: 'Allowance',
                            labelText:
                                (allowance * 60).toInt() == 0
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
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onChanged: (value) {
                            final parsedValue = int.tryParse(value) ?? 0;
                            final allowanceProvided =
                                parsedValue == 0 ? 0.0 : parsedValue / 60;
                            final allowanceNotifier = ref.read(
                              allowanceProvider.notifier,
                            );
                            final bonusInfoNotifier = ref.read(
                              bonusInfoListProvider.notifier,
                            );
                            allowanceNotifier.setAllowance(allowanceProvided);
                            bonusInfoNotifier.updateRatio(
                              focusedProduct.productName
                                  .toLowerCase()
                                  .trimRight(),
                              ref.read(targetProvider),
                              int.tryParse(numberController.text) ?? 0,
                              workingHours,
                              allowanceProvided,
                            );
                            _allowancePersistenceDebounce?.cancel();
                            _allowancePersistenceDebounce = Timer(
                              const Duration(milliseconds: 450),
                              () {
                                if (!mounted) return;
                                unawaited(
                                  ref
                                      .read(allowanceProvider.notifier)
                                      .persistAllowance(allowanceProvided),
                                );
                              },
                            );
                          },
                          onFieldSubmitted:
                              (_) => dismissTargetCheckInputs(ref),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!showList)
              SizedBox(
                height: cardHeight * 0.26,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final circleSize = constraints.maxHeight;
                    final targetSize = math.min(
                      circleSize * 1.28,
                      math.max(circleSize, constraints.maxWidth * 0.66),
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: circleSize,
                            height: circleSize,
                            child: _RatioSummary(
                              allowance: allowance,
                              targetRatio: targetRatio,
                              workingHours: workingHours,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 2.1,
                          child: TargetBoard(
                            productName: focusedProduct.productName,
                            size: targetSize,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            //add a new widget to the row
            if (!showList) const CustomSaveButton(),
            const SizedBox(height: 8),
            // const SlideToOvertime(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(WidgetRef ref) {
    final products = ref.watch(lastSelectedProductProvider);
    final source = ref.watch(productListSourceProvider);
    final hasLastSelected = products.isNotEmpty;
    final effectiveSource =
        hasLastSelected ? source : ProductListSource.allProducts;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<ProductListSource>(
              selected: {effectiveSource},
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ProductListSource.lastSelected,
                  label: const Text('Last selected'),
                  icon: const Icon(Icons.history_rounded),
                  enabled: hasLastSelected,
                ),
                const ButtonSegment(
                  value: ProductListSource.allProducts,
                  label: Text('All products'),
                  icon: Icon(Icons.list_rounded),
                ),
              ],
              onSelectionChanged: (selection) {
                ref.read(productListSourceProvider.notifier).state =
                    selection.single;
                ref.read(showListProvider.notifier).state = true;
              },
            ),
          ),
          if (effectiveSource == ProductListSource.lastSelected)
            const LastSelectedProducts()
          else
            const ProductsListSuggested(),
        ],
      ),
    );
  }
}

class _RatioSummary extends ConsumerWidget {
  const _RatioSummary({
    required this.allowance,
    required this.targetRatio,
    required this.workingHours,
  });

  final double allowance;
  final double targetRatio;
  final double workingHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonus =
        ref.watch(bonusCalculator(targetRatio)) *
        ((workingHours - allowance) / 7.00);

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.orange[50]!, Colors.orange[200]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Transform.scale(scale: 1.45, child: const RiveEllipses()),
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
              Text(
                '£ ${formatDouble(bonus)}',
                style: TextStyle(
                  color: Colors.green[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
