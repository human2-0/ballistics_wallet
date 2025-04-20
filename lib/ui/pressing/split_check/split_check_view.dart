import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitCheck extends ConsumerWidget {
  const SplitCheck({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final calc = ref.watch(splitCalculatorProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: const BorderRadius.all(Radius.circular(33)),
                    ),
                    child: const Column(
                      children: [
                        ProductPicker(), // handles Autocomplete<ProductInfo>
                        SizedBox(height: 16),
                        // const TargetPicker(), // handles Autocomplete<BonusItem>
                        // const SizedBox(height: 16),
                        AmountInput(), // NEW – manual “amount per batch” field
                        SizedBox(height: 16),
                        AmountSlider(), // slider + text input
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ResultsList(calc.perBatch),
          ],
        ),
      ),
    );
  }
}

class AmountInput extends ConsumerStatefulWidget {
  const AmountInput({super.key});

  @override
  _AmountInputState createState() => _AmountInputState();
}

class _AmountInputState extends ConsumerState<AmountInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialAmount = ref.read(amountPerBatchProvider);
    _controller = TextEditingController(text: initialAmount.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = ref.watch(amountPerBatchProvider);
    // Update the text when the provider changes, unless the user is editing
    if (!_focusNode.hasFocus && _controller.text != amount.toString()) {
      _controller.text = amount.toString();
    }
    return CustomTextField(
      controller: _controller,
      focusNode: _focusNode,
      hintText: 'Enter amount',
      labelText: 'Amount per batch',
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          ref.read(amountPerBatchProvider.notifier).state = parsed;
        }
      },
      showClearIcon: true,
    );
  }
}

class AmountSlider extends StatelessWidget {
  const AmountSlider({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (ctx, ref, _) {
        final raw = ref.watch(amountPerBatchProvider);
        final amt = raw.clamp(1, 150);
        return Slider(
          value: amt.toDouble(),
          min: 1,
          max: 150,
          divisions: 149,
          label: amt.toString(),
          onChanged: (v) =>
              ref.read(amountPerBatchProvider.notifier).state = v.round(),
        );
      },
    );
  }
}

class SplitCalculator {
  SplitCalculator(this.required, this.perBatch, this.hours);
  final int required;
  final int perBatch;
  final double hours;

  int get batches => (perBatch > 0 ? (required / perBatch).floor() : 1);
  int get extra => (perBatch > 0 ? (required % perBatch) : 0);
  int get timePerBatch =>
      batches > 0 ? ((hours - 0.25) / batches * 60).ceil() : 1;
}

class ProductPicker extends ConsumerStatefulWidget {
  const ProductPicker({super.key});

  @override
  ConsumerState<ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends ConsumerState<ProductPicker> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // use shared controller so that other widgets can read/write
    _controller = ref.read(productNameControllerProvider.notifier).controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(productInfoProvider);
    final workingHours =
        ref.watch(userNotifierProvider.select((u) => u.workingHours)) ?? 0.0;
    final allowance = ref.watch(allowanceProvider);

    return Autocomplete<ProductInfo>(
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: Material(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(33),
                topRight: Radius.circular(33),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              color: Colors.orange[100],
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                  minWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(2),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(33)),
                              color: Colors.orange[50],
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(33),
                              ),
                              title: Center(
                                child: Text(
                                  option.productName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              tileColor: Colors.white,
                              selectedTileColor: Colors.grey[200],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return const <ProductInfo>[];
        return allProducts
            .where((p) => p.productName.toLowerCase().contains(query));
      },
      displayStringForOption: (option) => option.productName,
      fieldViewBuilder: (context, fieldController, focusNode, onSubmitted) {
        // drive from shared controller
        fieldController.value = _controller.value;
        return CustomTextField(
          controller: fieldController,
          focusNode: focusNode,
          hintText: 'Add product name',
          labelText: 'Product',
          onSubmitted: (_) => onSubmitted(),
          showClearIcon: true,
        );
      },
      onSelected: (selection) async {
        // compute new target based on product target & hours
        final calculated =
            ((selection.target.toDouble()) * ((workingHours - allowance) / 7))
                .ceil();
        // update providers
        ref.read(targetProvider.notifier).state = calculated;
        ref.read(focusedProductProvider.notifier).state = selection;
        await ref
            .read(lastSelectedProductProvider.notifier)
            .saveSelectedProduct(selection);
        // update text
        setState(() {
          _controller.text = selection.productName;
        });
        if (context.mounted) {
          FocusScope.of(context).unfocus();
        }
      },
    );
  }
}

class ResultsList extends ConsumerWidget {
  const ResultsList(this.perBatch, {super.key});
  final int perBatch;

  String extractColorName(String s) {
    if (s.contains('-')) return s.split('-').last.trim();
    final parts = s.split(' ');
    return parts.length > 1 && isValidColor(parts.last)
        ? parts.last
        : parts.first;
  }

  String extractColorNameForUser(String s) {
    if (s.contains('-')) return s.split('-').last.trim();
    return s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(focusedProductProvider).product;
    if (list.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        final powderKg = ((item.systemG * perBatch) / 1000).toStringAsFixed(2);
        final citricKg =
            ((item.systemCitric * perBatch) / 1000).toStringAsFixed(2);
        final rawColor = extractColorName(item.productColor);
        final bg = getColorFromString(rawColor);
        final fg = getColorFromString(rawColor, accent: true);

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(33),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: fg,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.25,
                    child: Center(
                      child: Text(
                        extractColorNameForUser(item.productColor),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Powder: $powderKg kg',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Citric: $citricKg kg',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
