// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showEditWeightRangeDialog(
  BuildContext context,
  WidgetRef ref, {
  required ProductInfo product,
}) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _EditWeightRangeDialog(product: product),
  );
}

class _EditWeightRangeDialog extends ConsumerStatefulWidget {
  const _EditWeightRangeDialog({required this.product});

  final ProductInfo product;

  @override
  ConsumerState<_EditWeightRangeDialog> createState() =>
      _EditWeightRangeDialogState();
}

class _EditWeightRangeDialogState
    extends ConsumerState<_EditWeightRangeDialog> {
  late final TextEditingController _minWeightController;
  late final TextEditingController _maxWeightController;

  @override
  void initState() {
    super.initState();
    _minWeightController = TextEditingController(
      text: _formatWeight(widget.product.customWeightRangeMinGrams),
    );
    _maxWeightController = TextEditingController(
      text: _formatWeight(widget.product.customWeightRangeMaxGrams),
    );
  }

  @override
  void dispose() {
    _minWeightController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updatedWeightRange = _parseWeightRange(
      minText: _minWeightController.text,
      maxText: _maxWeightController.text,
    );
    if (!updatedWeightRange.isValid) {
      showAppNotification(
        context,
        'Enter a valid minimum and maximum weight.',
        type: AppNotificationType.error,
      );
      return;
    }

    final updatedProduct = ProductInfo(
      productName: widget.product.productName,
      target: widget.product.target,
      imageName: widget.product.imageName,
      product: widget.product.product,
      ayr: widget.product.ayr,
      description: widget.product.description,
      customWeightRangeMinGrams: updatedWeightRange.minGrams,
      customWeightRangeMaxGrams: updatedWeightRange.maxGrams,
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
      result ? 'Weight range updated.' : 'Failed to update weight range.',
      type: result ? AppNotificationType.success : AppNotificationType.error,
    );
    if (result) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Edit weight range', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _minWeightController,
                  hintText: '120',
                  labelText: 'Min (g)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  selectAllOnFocus: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _maxWeightController,
                  hintText: '130',
                  labelText: 'Max (g)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  selectAllOnFocus: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
  );
}

String _formatWeight(double? weightGrams) =>
    weightGrams == null ? '' : weightGrams.ceil().toString();

_ParsedWeightRange _parseWeightRange({
  required String minText,
  required String maxText,
}) {
  final minValue = minText.trim();
  final maxValue = maxText.trim();
  if (minValue.isEmpty && maxValue.isEmpty) {
    return const _ParsedWeightRange.valid();
  }

  final minGrams = double.tryParse(minValue);
  final maxGrams = double.tryParse(maxValue);
  if (minGrams == null || maxGrams == null) {
    return const _ParsedWeightRange.invalid();
  }
  if (minGrams <= 0 || maxGrams <= 0 || minGrams > maxGrams) {
    return const _ParsedWeightRange.invalid();
  }
  return _ParsedWeightRange.valid(minGrams: minGrams, maxGrams: maxGrams);
}

class _ParsedWeightRange {
  const _ParsedWeightRange.valid({this.minGrams, this.maxGrams})
    : isValid = true;

  const _ParsedWeightRange.invalid()
    : isValid = false,
      minGrams = null,
      maxGrams = null;

  final bool isValid;
  final double? minGrams;
  final double? maxGrams;
}
