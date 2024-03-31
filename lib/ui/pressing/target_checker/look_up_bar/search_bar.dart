import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchProductBar extends ConsumerStatefulWidget {
  const SearchProductBar({
    required this.numberController,
    required this.focusNode,
    super.key,
  });

  final TextEditingController numberController;
  final FocusNode focusNode;

  @override
  SearchProductBarState createState() => SearchProductBarState();
}

class SearchProductBarState extends ConsumerState<SearchProductBar> {
  @override
  Widget build(BuildContext context) {
    final showList = ref.watch(showListProvider);

    final controller =
        ref.watch(productNameControllerProvider.notifier).controller;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: AnimatedContainer(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange[100]!,
              Colors.orange[200]!,
              Colors.orange[300]!,
            ],
            stops: const [
              0.0,
              0.5,
              0.9,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        duration: const Duration(milliseconds: 400),
        width:
            ((showList || widget.focusNode.hasFocus || (controller.text != ''))
                ? MediaQuery.of(context).size.width * 0.66
                : MediaQuery.of(context).size.width * 0.12),
        child: TextField(
          focusNode: widget.focusNode,
          controller: controller,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            suffixIcon: controller.text.isEmpty
                ? const Icon(Icons.search_rounded)
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () async {
                      ref.read(focusedProductProvider.notifier).state =
                          ProductInfo(
                        productName: '',
                        product: [const Pressing('', 0, 0)],
                        imageName: 'question',
                        target: 0,
                      );

                      controller.clear();
                      ref.read(showListProvider.notifier).state = false;
                      ref.read(focusNodeProvider).unfocus();
                      widget.focusNode.unfocus();
                      widget.numberController.clear();

                      ref.read(targetProvider.notifier).state = 0;
                      ref.read(allowanceProvider.notifier).state = 0.0;
                      await ref.read(bonusInfoListProvider.notifier).init();
                      ref
                          .read(numberControllerProvider.notifier)
                          .controller
                          .clear();
                    },
                  ),
            hintStyle: const TextStyle(color: Colors.grey),
            hintText: 'Search',
          ),
          onTap: () {
            if (!showList) {
              ref.read(showListProvider.notifier).state = true;

              FocusScope.of(context).requestFocus(FocusNode());
              widget.numberController.clear();
            }
          },
          onChanged: (value) {
            controller.text = value;
          },
          onSubmitted: (value) {
            ref.read(showListProvider.notifier).state = false;
          },
        ),
      ),
    );
  }
}
