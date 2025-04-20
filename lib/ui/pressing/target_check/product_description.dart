import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart' show lastSelectedProductProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showProductNoteDialog(BuildContext context, WidgetRef ref) async {
  final product = ref.read(focusedProductProvider);
  final originalDescription = product.description ?? '';
  final controller = TextEditingController(text: originalDescription);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      // local state for “edit / view” mode
      var isEditing = originalDescription.isEmpty;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            product.productName.isEmpty
                ? 'Product note'
                : '${product.productName} note',
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            readOnly: !isEditing,
            decoration: InputDecoration(
              hintText: isEditing
                  ? 'Add tips, tricks, sweet‑spot powder amounts, or anything else helpful…'
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            if (!isEditing) // VIEW‑ONLY:  Edit  |  Close
              TextButton(
                onPressed: () {
                  setState(() => isEditing = true);
                },
                child: const Text('Edit'),
              ),
            if (isEditing) // EDITING:  Cancel  |  Save
              TextButton(
                onPressed: () {
                  // revert changes & switch back to view mode
                  controller.text = originalDescription;
                  setState(() => isEditing = false);
                },
                child: const Text('Cancel'),
              ),
            if (!isEditing)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            if (isEditing)
              ElevatedButton(
                onPressed: () async {
                  final updated = product.copyWith(description: controller.text);
                  // update the local “focused” product

                  // persist to Firestore
                  await ref.read(productInfoProvider.notifier).editProductInfo(updated);
                  await ref
                      .read(lastSelectedProductProvider.notifier)
                      .saveSelectedProduct(updated);
                  ref.read(focusedProductProvider.notifier).state = updated;
                  if (context.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save'),
              ),
          ],
        ),
      );
    },
  );
}
