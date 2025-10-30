import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart'
    show lastSelectedProductProvider;
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum HistorySort { newest, oldest, highestBonus }

Future<void> showProductNoteDialog(BuildContext context, WidgetRef ref) async {
  final product = ref.read(focusedProductProvider);
  final originalDescription = product.description ?? '';
  final controller = TextEditingController(text: originalDescription);
  final history = ref
      .read(bonusInfoListProvider.notifier)
      .getProductHistory(product.productName);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      // local state for “edit / view” mode
      var isEditing = originalDescription.isEmpty;
      var sort = HistorySort.newest;
      return StatefulBuilder(
        builder: (context, setState) {
          // Prepare a sorted copy of history according to the selected sort mode
          final sortedHistory = [...history];
          switch (sort) {
            case HistorySort.highestBonus:
              sortedHistory.sort((a, b) => b.bonus.compareTo(a.bonus));
            case HistorySort.newest:
              sortedHistory.sort((a, b) => b.date.compareTo(a.date));
            case HistorySort.oldest:
              sortedHistory.sort((a, b) => a.date.compareTo(b.date));
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              // keep the sheet above the keyboard
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    product.productName.isEmpty
                        ? 'Product note'
                        : '${product.productName} note',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 80,
                      maxHeight: 160,
                    ),
                    child: TextField(
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
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        sort == HistorySort.highestBonus
                            ? 'Highest bonus'
                            : (sort == HistorySort.oldest ? 'Oldest' : 'Newest'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<HistorySort>(
                        tooltip: 'Sort history',
                        icon: const Icon(Icons.sort),
                        onSelected: (value) => setState(() => sort = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: HistorySort.newest,
                            child: Text('Newest'),
                          ),
                          PopupMenuItem(
                            value: HistorySort.oldest,
                            child: Text('Oldest'),
                          ),
                          PopupMenuItem(
                            value: HistorySort.highestBonus,
                            child: Text('Highest bonus'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: history.isEmpty
                        ? const Center(child: Text('No history available.'))
                        : ListView.builder(
                            itemCount: sortedHistory.length,
                            itemBuilder: (context, index) {
                              final entry = sortedHistory[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        offset: const Offset(4, 4),
                                        blurRadius: 6,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha:0.7),
                                        offset: const Offset(-4, -4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text('£ ${entry.bonus.toStringAsFixed(0)}'),
                                    subtitle: Text(DateFormat.yMMMd().format(entry.date)),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isEditing)
                        OutlinedButton(
                          onPressed: () => setState(() => isEditing = true),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Edit'),
                        ),
                      if (isEditing)
                        OutlinedButton(
                          onPressed: () {
                            controller.text = originalDescription;
                            setState(() => isEditing = false);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      if (!isEditing)
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Close'),
                        ),
                      if (isEditing)
                        ElevatedButton(
                          onPressed: () async {
                            final updated = product.copyWith(description: controller.text);
                            await ref.read(productInfoProvider.notifier).editProductInfo(updated);
                            await ref.read(lastSelectedProductProvider.notifier).saveSelectedProduct(updated);
                            ref.read(focusedProductProvider.notifier).state = updated;
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Save'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
