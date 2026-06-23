// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: DecoratedBox(
        decoration: boxDecoration(),
        child: AnimatedContainer(
          decoration: BoxDecoration(
            color: Colors.yellowAccent[100],
            borderRadius: BorderRadius.circular(33),
          ),
          duration: const Duration(milliseconds: 400),
          width:
              (isRevealed
                  ? MediaQuery.of(context).size.width * 0.75
                  : MediaQuery.of(context).size.width * 0.12),
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(2),
              border: InputBorder.none,
              prefixIcon:
                  isRevealed ? _EffortFilterButton(filter: effortFilter) : null,
              suffixIcon:
                  controller.text.isEmpty
                      ? const Icon(Icons.search_rounded)
                      : IconButton(
                        icon: const Icon(Icons.clear),
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
              hintStyle: const TextStyle(color: Colors.grey),
              hintText: _hintForFilter(effortFilter),
            ),
            textInputAction: TextInputAction.done,
            onTap: () {
              openProductLookup(ref);
              widget.numberController.clear();
            },
            onChanged: (value) {
              ref
                  .read(productListSourceProvider.notifier)
                  .state = _sourceForSearchInput(ref, value);
              ref.read(showListProvider.notifier).state = true;
            },
            onEditingComplete: () => dismissTargetCheckInputs(ref),
          ),
        ),
      ),
    );
  }
}

ProductListSource _sourceForSearchInput(WidgetRef ref, String value) {
  if (value.trim().isEmpty &&
      ref.read(lastSelectedProductProvider).isNotEmpty) {
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
          color: filter == ProductEffortFilter.none ? null : Colors.deepOrange,
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
