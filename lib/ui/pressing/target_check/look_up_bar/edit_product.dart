// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEditProductDialog(
  BuildContext context,
  WidgetRef ref, {
  required ProductInfo product,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _EditProductDialog(product: product),
  );
}

class _EditProductDialog extends ConsumerStatefulWidget {
  const _EditProductDialog({required this.product});

  final ProductInfo product;

  @override
  ConsumerState<_EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<_EditProductDialog> {
  late final TextEditingController _productNameController;
  late final TextEditingController _targetController;
  late final TextEditingController _weightRangeMinController;
  late final TextEditingController _weightRangeMaxController;
  late final TextEditingController _ratioController;
  late final List<PressingEntry> _pressingEntries;

  var _customCitric = false;
  var _selectedRatio = 3.0;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(
      text: widget.product.productName,
    );
    _targetController = TextEditingController(
      text: widget.product.target.toString(),
    );
    _weightRangeMinController = TextEditingController(
      text: _formatWeightValue(widget.product.customWeightRangeMinGrams),
    );
    _weightRangeMaxController = TextEditingController(
      text: _formatWeightValue(widget.product.customWeightRangeMaxGrams),
    );
    _ratioController = TextEditingController(
      text: _selectedRatio.toStringAsFixed(1),
    );
    _pressingEntries =
        widget.product.product.map(PressingEntry.fromPressing).toList();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _targetController.dispose();
    _weightRangeMinController.dispose();
    _weightRangeMaxController.dispose();
    _ratioController.dispose();
    for (final entry in _pressingEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addPressingEntry() {
    setState(() {
      _pressingEntries.add(PressingEntry());
    });
  }

  void _removePressingEntry(int index) {
    final entry = _pressingEntries[index];
    setState(() {
      _pressingEntries.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      entry.dispose();
    });
  }

  void _setRatio(double value) {
    setState(() {
      _selectedRatio = value;
      _ratioController.text = value.toStringAsFixed(1);
      _populateCitricControllers();
    });
  }

  void _populateCitricControllers() {
    for (final entry in _pressingEntries) {
      final powder = double.tryParse(entry.systemGController.text) ?? 0.0;
      entry.systemCitricController.text = (powder / _selectedRatio)
          .toStringAsFixed(2);
    }
  }

  Future<void> _save() async {
    final updatedTarget = int.tryParse(_targetController.text.trim());
    if (updatedTarget == null) {
      showAppNotification(
        context,
        'Invalid target value.',
        type: AppNotificationType.error,
      );
      return;
    }

    final updatedWeightRange = _parseWeightRange(
      minValue: _weightRangeMinController.text.trim(),
      maxValue: _weightRangeMaxController.text.trim(),
    );
    if (updatedWeightRange == null &&
        (_weightRangeMinController.text.trim().isNotEmpty ||
            _weightRangeMaxController.text.trim().isNotEmpty)) {
      showAppNotification(
        context,
        'Enter both min and max weights, with min not greater than max.',
        type: AppNotificationType.error,
      );
      return;
    }

    final updatedPressings =
        _pressingEntries.map((entry) {
          final powder = double.tryParse(entry.systemGController.text) ?? 0.0;
          final citric =
              _customCitric
                  ? double.tryParse(entry.systemCitricController.text) ?? 0.0
                  : powder / _selectedRatio;
          return Pressing(entry.colorController.text, powder, citric);
        }).toList();

    final updatedProduct = ProductInfo(
      productName: widget.product.productName,
      target: updatedTarget,
      imageName: widget.product.imageName,
      product: updatedPressings,
      ayr: widget.product.ayr,
      description: widget.product.description,
      customWeightRangeMinGrams: updatedWeightRange?.minGrams,
      customWeightRangeMaxGrams: updatedWeightRange?.maxGrams,
      imageScale: widget.product.imageScale,
      imageOffsetX: widget.product.imageOffsetX,
      imageOffsetY: widget.product.imageOffsetY,
    );

    final result = await ref
        .read(productInfoProvider.notifier)
        .editProductInfo(updatedProduct);
    if (result) {
      await ref
          .read(lastSelectedProductProvider.notifier)
          .deleteSelectedProductByName(widget.product.productName);
      await ref
          .read(lastSelectedProductProvider.notifier)
          .saveSelectedProduct(updatedProduct);

      final focusedProduct = ref.read(focusedProductProvider);
      if (focusedProduct.productName == widget.product.productName) {
        ref.read(focusedProductProvider.notifier).state = updatedProduct;
        ref.read(targetProvider.notifier).state = updatedProduct.target;
        ref.read(productNameControllerProvider.notifier).controller.text =
            updatedProduct.productName;
      }
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showAppNotification(
      context,
      result ? 'Product updated.' : 'Failed to update product.',
      type: result ? AppNotificationType.success : AppNotificationType.error,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasEntries = _pressingEntries.isNotEmpty;

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit product', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _productNameController,
                hintText: 'Product Name',
                labelText: 'Product Name',
                enabled: false,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _targetController,
                hintText: 'Target',
                labelText: 'Target',
                keyboardType: TextInputType.number,
                selectAllOnFocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _weightRangeMinController,
                      hintText: '120',
                      labelText: 'Min weight (g)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      selectAllOnFocus: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightRangeMaxController,
                      hintText: '130',
                      labelText: 'Max weight (g)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      selectAllOnFocus: true,
                    ),
                  ),
                ],
              ),
              if (hasEntries) ...[
                const SizedBox(height: 16),
                const Divider(height: 2, color: Colors.grey),
                const SizedBox(height: 16),
                _InfoTile(
                  title:
                      'Ratio: ${_selectedRatio.toStringAsFixed(1)} parts powder to 1 part citric',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Slider(
                      value: _selectedRatio,
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: _selectedRatio.toStringAsFixed(1),
                      onChanged: _setRatio,
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.22,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.5),
                              offset: const Offset(-2, 2.5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _ratioController,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            hintText: 'Ratio',
                            filled: true,
                            fillColor: Colors.orange[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(33),
                              borderSide: BorderSide.none,
                            ),
                            labelText: 'Ratio',
                            labelStyle: const TextStyle(fontSize: 18),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onSubmitted: (value) {
                            final manualInput = double.tryParse(value);
                            if (manualInput != null &&
                                manualInput >= 1 &&
                                manualInput <= 15) {
                              _setRatio(manualInput);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _RatioBar(selectedRatio: _selectedRatio),
                const SizedBox(height: 16),
                const Divider(height: 2, color: Colors.grey),
                const SizedBox(height: 16),
                const _InfoTile(title: 'Add amount in grams per one bath bomb'),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _pressingEntries.length,
                  itemBuilder:
                      (context, index) => Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        child: _PressingEntryRow(
                          entry: _pressingEntries[index],
                          index: index,
                          customCitric: _customCitric,
                          onPowderChanged: _populateCitricControllers,
                          onRemove: () => _removePressingEntry(index),
                        ),
                      ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Custom Citric Amount?'),
                  Checkbox(
                    value: _customCitric,
                    onChanged: (value) {
                      setState(() {
                        _customCitric = value ?? false;
                        if (_customCitric) {
                          _populateCitricControllers();
                        }
                      });
                    },
                  ),
                ],
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.33,
                child: IconButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateColor.resolveWith(
                      (states) => Colors.greenAccent.withValues(alpha: 0.8),
                    ),
                  ),
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Add color'),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const SweepGradient(
                            colors: [
                              Colors.red,
                              Colors.orange,
                              Colors.yellow,
                              Colors.green,
                              Colors.blue,
                              Colors.indigo,
                              Colors.purple,
                              Colors.pink,
                            ],
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.5),
                              offset: const Offset(-2, 2.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.transparent),
                      ),
                    ],
                  ),
                  color: Colors.brown,
                  onPressed: _addPressingEntry,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      boxShadow: [
        BoxShadow(
          color: Colors.yellow[100]!.withValues(alpha: 0.8),
          offset: const Offset(4, -2.5),
        ),
      ],
    ),
    child: Material(
      color: Colors.yellow[500]!.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: const Icon(Icons.info_outline_rounded),
        title: Text(title),
      ),
    ),
  );
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.selectedRatio});

  final double selectedRatio;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.66;
    final powderWidth = width * (selectedRatio / (selectedRatio + 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const SweepGradient(
              colors: [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
                Colors.pink,
                Colors.red,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(33),
              topLeft: Radius.circular(33),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withValues(alpha: 0.5),
                offset: const Offset(-2, 2.5),
                blurRadius: 8,
              ),
            ],
          ),
          width: powderWidth,
          height: 50,
          child: const Center(
            child: Text('Powder', style: TextStyle(color: Colors.white)),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(33),
              topRight: Radius.circular(33),
            ),
          ),
          width: width - powderWidth,
          height: 50,
          child: const Center(child: Text('Citric')),
        ),
      ],
    );
  }
}

class _PressingEntryRow extends StatelessWidget {
  const _PressingEntryRow({
    required this.entry,
    required this.index,
    required this.customCitric,
    required this.onPowderChanged,
    required this.onRemove,
  });

  final PressingEntry entry;
  final int index;
  final bool customCitric;
  final VoidCallback onPowderChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CustomTextField(
          controller: entry.colorController,
          focusNode: entry.colorFocusNode,
          hintText: 'Color ${index + 1}',
          labelText: 'Color ${index + 1}',
          selectAllOnFocus: true,
        ),
      ),
      Expanded(
        child: CustomTextField(
          controller: entry.systemGController,
          focusNode: entry.systemGFocusNode,
          hintText: 'Powder',
          labelText: 'Powder',
          selectAllOnFocus: true,
          onChanged: (_) => onPowderChanged(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ),
      if (customCitric)
        Expanded(
          child: CustomTextField(
            controller: entry.systemCitricController,
            focusNode: entry.systemCitricFocusNode,
            hintText: 'Citric',
            labelText: 'Citric',
            selectAllOnFocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: onRemove,
      ),
    ],
  );
}

String _formatWeightValue(double? grams) {
  if (grams == null) return '';
  if (grams == grams.roundToDouble()) return grams.toInt().toString();
  return grams.toString();
}

_ParsedWeightRange? _parseWeightRange({
  required String minValue,
  required String maxValue,
}) {
  if (minValue.isEmpty && maxValue.isEmpty) return null;
  if (minValue.isEmpty || maxValue.isEmpty) return null;
  final minGrams = double.tryParse(minValue);
  final maxGrams = double.tryParse(maxValue);
  if (minGrams == null || maxGrams == null) return null;
  if (minGrams <= 0 || maxGrams <= 0 || minGrams > maxGrams) return null;
  return _ParsedWeightRange(minGrams, maxGrams);
}

class _ParsedWeightRange {
  const _ParsedWeightRange(this.minGrams, this.maxGrams);

  final double minGrams;
  final double maxGrams;
}

class PressingEntry {
  PressingEntry({
    String color = '',
    double systemG = 0.0,
    double systemCitric = 0.0,
  }) : colorController = TextEditingController(text: color),
       systemGController = TextEditingController(
         text: systemG.toStringAsFixed(2),
       ),
       systemCitricController = TextEditingController(
         text: systemCitric.toStringAsFixed(2),
       ),
       colorFocusNode = FocusNode(),
       systemGFocusNode = FocusNode(),
       systemCitricFocusNode = FocusNode();

  factory PressingEntry.fromPressing(Pressing pressing) => PressingEntry(
    color: pressing.productColor,
    systemG: pressing.systemG,
    systemCitric: pressing.systemCitric,
  );

  final TextEditingController colorController;
  final TextEditingController systemGController;
  final TextEditingController systemCitricController;
  final FocusNode colorFocusNode;
  final FocusNode systemGFocusNode;
  final FocusNode systemCitricFocusNode;

  void dispose() {
    colorController.dispose();
    systemGController.dispose();
    systemCitricController.dispose();
    colorFocusNode.dispose();
    systemGFocusNode.dispose();
    systemCitricFocusNode.dispose();
  }
}
