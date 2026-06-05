import 'dart:math';

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

enum _ColorAction { custom, clearCustom, selectColor, clearColor }

String _colorLabel(String value) {
  if (value.isEmpty) return value;
  if (value.startsWith('#') || value.toLowerCase().startsWith('0x')) {
    return 'Custom';
  }
  return value[0].toUpperCase() + value.substring(1);
}

Future<void> _showCustomAmountDialog(
  BuildContext context,
  WidgetRef ref, {
  required String colorKey,
  required int initialValue,
}) async {
  final controller = TextEditingController(text: initialValue.toString());
  final focusNode = FocusNode();
  await showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Custom amount per batch'),
          content: CustomTextField(
            controller: controller,
            focusNode: focusNode,
            hintText: 'Enter custom amount',
            labelText: 'Amount per batch',
            keyboardType: TextInputType.number,
            showClearIcon: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final raw = controller.text.trim();
                final next = {...ref.read(perColorOverridesProvider)};
                if (raw.isEmpty) {
                  // Empty input clears the custom override (revert to global per-batch)
                  next.remove(colorKey);
                } else {
                  final val = int.tryParse(raw);
                  if (val != null && val >= 0) {
                    // Allow any non-negative integer; 0 means contribute nothing
                    next[colorKey] = val;
                  }
                }
                ref.read(perColorOverridesProvider.notifier).state = next;
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
  );
}

Future<void> _showColorPickerDialog(
  BuildContext context,
  WidgetRef ref, {
  required String colorKey,
  required String? currentValue,
}) async {
  final isNamed =
      currentValue != null &&
      splitCheckColorOptions.contains(currentValue.toLowerCase());
  final initialNamed = isNamed ? currentValue.toLowerCase() : null;
  final initialParsed =
      currentValue != null ? parseColorString(currentValue) : null;
  final initialColor =
      initialParsed ??
      (initialNamed != null ? getColorFromString(initialNamed) : Colors.blue);
  var selectedColor = initialColor;
  var selectedName = initialNamed;

  await showDialog<void>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Select color'),
          content: StatefulBuilder(
            builder:
                (context, setState) => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HueWheelPicker(
                        size: (MediaQuery.of(context).size.width * 0.8).clamp(
                          210.0,
                          320.0,
                        ),
                        color: selectedColor,
                        onChanged: (next) {
                          setState(() {
                            selectedColor = next;
                            selectedName = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(colorToHex(selectedColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            splitCheckColorOptions.map((name) {
                              final isSelected = selectedName == name;
                              return ChoiceChip(
                                label: Text(_colorLabel(name)),
                                selected: isSelected,
                                selectedColor: getColorFromString(
                                  name,
                                  accent: true,
                                ),
                                backgroundColor: getColorFromString(name),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.black
                                          : Colors.black87,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    selectedName = name;
                                    selectedColor = getColorFromString(name);
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = selectedName ?? colorToHex(selectedColor);
                ref
                    .read(perColorDisplayOverridesProvider.notifier)
                    .setOverride(colorKey, value);
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
  );
}

class _HueWheelPicker extends StatelessWidget {
  const _HueWheelPicker({
    required this.size,
    required this.color,
    required this.onChanged,
  });

  final double size;
  final Color color;
  final ValueChanged<Color> onChanged;

  void _handleChange(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final radius = size.width / 2;
    final distance = sqrt(dx * dx + dy * dy);
    if (distance > radius) return;
    final hue = (atan2(dy, dx) * 180 / pi + 360) % 360;
    final saturation = (distance / radius).clamp(0.0, 1.0);
    final next = HSVColor.fromAHSV(1, hue, saturation, 1).toColor();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final paintSize = Size(size, size);
    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanDown: (details) => _handleChange(details.localPosition, paintSize),
        onPanUpdate:
            (details) => _handleChange(details.localPosition, paintSize),
        onTapDown: (details) => _handleChange(details.localPosition, paintSize),
        child: CustomPaint(size: paintSize, painter: _HueWheelPainter(color)),
      ),
    );
  }
}

class _HueWheelPainter extends CustomPainter {
  _HueWheelPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final hueShader = const SweepGradient(
      colors: [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
    ).createShader(rect);
    final huePaint = Paint()..shader = hueShader;
    canvas.drawCircle(center, radius, huePaint);

    final satShader = RadialGradient(
      colors: [Colors.white, Colors.white.withValues(alpha: 0)],
    ).createShader(rect);
    final satPaint = Paint()..shader = satShader;
    canvas.drawCircle(center, radius, satPaint);

    final hsv = HSVColor.fromColor(color);
    final angle = hsv.hue * pi / 180;
    final r = hsv.saturation * radius;
    final indicator = Offset(
      center.dx + cos(angle) * r,
      center.dy + sin(angle) * r,
    );
    final fillPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final whiteStrokePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final darkStrokePaint =
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    canvas
      ..drawCircle(indicator, 8, fillPaint)
      ..drawCircle(indicator, 8, whiteStrokePaint)
      ..drawCircle(indicator, 8, darkStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _HueWheelPainter oldDelegate) =>
      oldDelegate.color != color;
}

class SplitCheck extends ConsumerWidget {
  const SplitCheck({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final calc = ref.watch(splitCalculatorProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(ctx).unfocus(), // dismisses keyboard on tap
      behavior:
          HitTestBehavior.opaque, // ensures even empty space registers tap
      child: Padding(
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
                        borderRadius: const BorderRadius.all(
                          Radius.circular(33),
                        ),
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
      ),
    );
  }
}

class AmountInput extends ConsumerStatefulWidget {
  const AmountInput({super.key});

  @override
  ConsumerState<AmountInput> createState() => _AmountInputState();
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
  Widget build(BuildContext context) => Consumer(
    builder: (ctx, ref, _) {
      final raw = ref.watch(amountPerBatchProvider);
      final amt = raw.clamp(1, 150);
      return Slider(
        value: amt.toDouble(),
        min: 1,
        max: 150,
        divisions: 149,
        label: amt.toString(),
        onChanged:
            (v) => ref.read(amountPerBatchProvider.notifier).state = v.round(),
      );
    },
  );
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
      optionsViewBuilder:
          (context, onSelected, options) => Align(
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
                        return Padding(
                          padding: const EdgeInsets.all(4),
                          child: Material(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(33),
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
                              selectedTileColor: Colors.grey[200],
                              onTap: () => onSelected(option),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return const <ProductInfo>[];
        return allProducts.where(
          (p) => p.productName.toLowerCase().contains(query),
        );
      },
      displayStringForOption: (option) => option.productName,
      initialValue: _controller.value,
      fieldViewBuilder:
          (context, fieldController, focusNode, onSubmitted) => CustomTextField(
            controller: fieldController,
            focusNode: focusNode,
            hintText: 'Add product name',
            labelText: 'Product',
            onChanged: (_) {
              if (_controller.value != fieldController.value) {
                _controller.value = fieldController.value;
              }
            },
            onSubmitted: (_) => onSubmitted(),
            showClearIcon: true,
          ),
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

    final overrides = ref.watch(perColorOverridesProvider);
    final colorOverrides = ref.watch(perColorDisplayOverridesProvider);

    final header =
        overrides.isEmpty
            ? const SizedBox.shrink()
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text('Custom: ${overrides.length}')),
                  TextButton(
                    onPressed: () {
                      ref.read(perColorOverridesProvider.notifier).state = {};
                    },
                    child: const Text('Reset all'),
                  ),
                ],
              ),
            );

    final items = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        final colorKey = item.productColor;
        final hasCustom = overrides.containsKey(colorKey);
        final hasColorOverride = colorOverrides.containsKey(colorKey);
        final usedPerBatch = overrides[colorKey] ?? perBatch;
        final colorName =
            colorOverrides[colorKey] ?? extractColorName(item.productColor);
        final powderKg = ((item.systemG * usedPerBatch) / 1000).toStringAsFixed(
          2,
        );
        final citricKg = ((item.systemCitric * usedPerBatch) / 1000)
            .toStringAsFixed(2);
        final bg = getColorFromString(colorName);
        final fg = getColorFromString(colorName, accent: true);

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              Container(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                extractColorNameForUser(item.productColor),
                                style: const TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              if (hasCustom) const SizedBox(height: 4),
                              if (hasCustom)
                                const Text(
                                  'Custom',
                                  style: TextStyle(fontSize: 12),
                                ),
                              if (hasColorOverride) const SizedBox(height: 2),
                              if (hasColorOverride)
                                Text(
                                  'Color: ${_colorLabel(colorName)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
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
                          const SizedBox(height: 6),
                          Text(
                            '$usedPerBatch / batch',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: PopupMenuButton<_ColorAction>(
                  onSelected: (action) async {
                    switch (action) {
                      case _ColorAction.custom:
                        await _showCustomAmountDialog(
                          context,
                          ref,
                          colorKey: colorKey,
                          initialValue:
                              hasCustom
                                  ? (overrides[colorKey] ?? perBatch)
                                  : perBatch,
                        );
                      case _ColorAction.clearCustom:
                        final next = {...ref.read(perColorOverridesProvider)};
                        next.remove(colorKey);
                        ref.read(perColorOverridesProvider.notifier).state =
                            next;
                      case _ColorAction.selectColor:
                        await _showColorPickerDialog(
                          context,
                          ref,
                          colorKey: colorKey,
                          currentValue: colorOverrides[colorKey],
                        );
                      case _ColorAction.clearColor:
                        ref
                            .read(perColorDisplayOverridesProvider.notifier)
                            .clearOverride(colorKey);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: _ColorAction.selectColor,
                          child: Text('Select color...'),
                        ),
                        const PopupMenuItem(
                          value: _ColorAction.custom,
                          child: Text('Custom amount...'),
                        ),
                        if (hasCustom)
                          const PopupMenuItem(
                            value: _ColorAction.clearCustom,
                            child: Text('Clear custom'),
                          ),
                        if (hasColorOverride)
                          const PopupMenuItem(
                            value: _ColorAction.clearColor,
                            child: Text('Clear color'),
                          ),
                      ],
                ),
              ),
            ],
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, items],
    );
  }
}
