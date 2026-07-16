// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/app_glass_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class SearchProductBar extends ConsumerStatefulWidget {
  const SearchProductBar({required this.numberController, super.key});

  final TextEditingController numberController;

  @override
  SearchProductBarState createState() => SearchProductBarState();
}

class SearchProductBarState extends ConsumerState<SearchProductBar> {
  @override
  Widget build(BuildContext context) {
    final focusNode = ref.watch(focusNodeProvider);
    final showList = ref.watch(showListProvider);
    final effortFilter = ref.watch(productEffortFilterProvider);

    final controller =
        ref.watch(productNameControllerProvider.notifier).controller;
    final isRevealed = showList || focusNode.hasFocus || controller.text != '';
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width:
            (isRevealed
                ? MediaQuery.sizeOf(context).width * 0.75
                : MediaQuery.sizeOf(context).width * 0.12),
        height: 48,
        child: GlassContainer(
          useOwnLayer: true,
          // This bar is deliberately outside the scrolling target card, so the
          // premium Impeller path can capture and refract the screen artwork.
          quality: GlassQuality.premium,
          settings: appGlassSettings,
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            cursorColor: appGlassOnSurface,
            style: const TextStyle(
              color: appGlassOnSurface,
              fontWeight: FontWeight.w600,
              shadows: appGlassTextShadows,
            ),
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(2),
              border: InputBorder.none,
              prefixIcon:
                  isRevealed ? _EffortFilterButton(filter: effortFilter) : null,
              suffixIcon:
                  controller.text.isEmpty
                      ? const Icon(
                        Icons.search_rounded,
                        color: appGlassOnSurface,
                      )
                      : IconButton(
                        color: appGlassOnSurface,
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () async {
                          ref
                              .read(focusedProductProvider.notifier)
                              .state = ProductInfo(
                            productName: '',
                            product: [const Pressing('', 0, 0)],
                            imageName: 'question',
                            target: 0,
                          );

                          controller.clear();
                          widget.numberController.clear();

                          openProductLookup(ref);
                          focusNode.requestFocus();

                          ref.read(targetProvider.notifier).state = 0;
                          await ref.read(bonusInfoListProvider.notifier).init();
                          ref
                              .read(numberControllerProvider.notifier)
                              .controller
                              .clear();
                        },
                      ),
              hintStyle: const TextStyle(
                color: appGlassOnSurfaceMuted,
                fontWeight: FontWeight.w600,
                shadows: appGlassTextShadows,
              ),
              hintText: _hintForFilter(effortFilter),
            ),
            textInputAction: TextInputAction.done,
            onTapAlwaysCalled: true,
            onTap: () {
              openProductLookup(ref);
              widget.numberController.clear();
            },
            onChanged: (value) {
              ref
                  .read(productListSourceProvider.notifier)
                  .state = _sourceForSearchInput(value);
              ref.read(showListProvider.notifier).state = true;
            },
            onEditingComplete: () => dismissTargetCheckInputs(ref),
          ),
        ),
      ),
    );
  }
}

ProductListSource _sourceForSearchInput(String value) {
  if (value.trim().isEmpty) {
    return ProductListSource.lastSelected;
  }
  return ProductListSource.allProducts;
}

class _EffortFilterButton extends ConsumerWidget {
  const _EffortFilterButton({required this.filter});

  final ProductEffortFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      PopupMenuButton<ProductEffortFilter>(
        tooltip: 'Filter',
        initialValue: filter,
        icon: Icon(
          Icons.filter_list,
          color:
              filter == ProductEffortFilter.none
                  ? appGlassOnSurface
                  : appGlassAccent,
        ),
        onSelected: (value) {
          ref.read(productEffortFilterProvider.notifier).state = value;
          ref.read(showListProvider.notifier).state = true;
        },
        itemBuilder:
            (context) => const [
              PopupMenuItem(
                value: ProductEffortFilter.none,
                child: Text('Filter: normal'),
              ),
              PopupMenuItem(
                value: ProductEffortFilter.leastEffort,
                child: Text('Filter: least effort'),
              ),
              PopupMenuItem(
                value: ProductEffortFilter.maxEffort,
                child: Text('Filter: max effort'),
              ),
            ],
      );
}

String _hintForFilter(ProductEffortFilter filter) {
  switch (filter) {
    case ProductEffortFilter.none:
      return 'Search';
    case ProductEffortFilter.leastEffort:
      return 'Search - least effort';
    case ProductEffortFilter.maxEffort:
      return 'Search - max effort';
  }
}
