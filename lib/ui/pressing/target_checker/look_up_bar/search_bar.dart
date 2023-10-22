import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../../providers/auth_providers/auth_provider.dart';
import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';

class SearchProductBar extends ConsumerWidget {
  final TextEditingController textEditingController;
  final TextEditingController numberController;
  final FocusNode focusNode;
  const SearchProductBar({
    Key? key,
    required this.textEditingController,
    required this.numberController,
    required this.focusNode,
  }) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showList = ref.watch(showListProvider);

    final userId = ref.watch(authRepositoryProvider).currentUserId;


    return Padding(
      padding: const EdgeInsets.all(8.0),
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
        width: ((showList ||
                focusNode.hasFocus ||
                (textEditingController.text != ""))
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
                      ref.read(searchTermProvider.notifier).state = "";
                      ref.read(selectedProductProvider.notifier).state.state =
                          "";
                      textEditingController.clear();
                      ref.read(showListProvider.notifier).state = false;
                      ref.read(focusNodeProvider).unfocus();
                      focusNode.unfocus();
                      numberController.clear();

                      ref.read(targetProvider.notifier).updateTarget(0);
                      ref.read(allowanceProvider.notifier).state = 0.0;
                      ref.read(targetRatioProvider(userId).notifier).init();
                      ref.read(numberProvider.notifier).state = 0;
                    },
                  ),
            hintStyle: const TextStyle(color: Colors.grey),
            hintText: "Search",
          ),
          onTap: () {
            if (!showList) {
              ref.read(showListProvider.notifier).state = true;

              FocusScope.of(context).requestFocus(FocusNode());
              numberController.clear();
            }
          },
          onChanged: (value) {
            ref.read(searchTermProvider.notifier).state = value;
            ref.read(selectedProductProvider.notifier).state.state = value;

          },
          onSubmitted: (value) {
            ref.read(showListProvider.notifier).state = false;
          },
        ),
      ),
    );
  }
}
