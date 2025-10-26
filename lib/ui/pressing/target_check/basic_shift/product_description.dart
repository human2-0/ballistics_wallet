import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart'
    show lastSelectedProductProvider;
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum HistoryFilter { latest, oldest, highestBonus }

extension HistoryFilterLabel on HistoryFilter {
  String get label {
    switch (this) {
      case HistoryFilter.latest:
        return 'Latest';
      case HistoryFilter.oldest:
        return 'Oldest';
      case HistoryFilter.highestBonus:
        return 'Highest bonus';
    }
  }
}

List<BonusInfo> sortHistoryEntries(
  List<BonusInfo> history,
  HistoryFilter filter,
) {
  final sorted = [...history];
  int compareByDate(BonusInfo a, BonusInfo b) => a.date.compareTo(b.date);
  int compareByBonus(BonusInfo a, BonusInfo b) => a.bonus.compareTo(b.bonus);

  switch (filter) {
    case HistoryFilter.latest:
      sorted.sort((a, b) {
        final comparison = compareByDate(b, a);
        return comparison == 0 ? compareByBonus(b, a) : comparison;
      });
      break;
    case HistoryFilter.oldest:
      sorted.sort((a, b) {
        final comparison = compareByDate(a, b);
        return comparison == 0 ? compareByBonus(b, a) : comparison;
      });
      break;
    case HistoryFilter.highestBonus:
      sorted.sort((a, b) {
        final comparison = compareByBonus(b, a);
        return comparison == 0 ? compareByDate(b, a) : comparison;
      });
      break;
  }

  return sorted;
}

Future<void> showProductNoteDialog(BuildContext context, WidgetRef ref) async {
  final product = ref.read(focusedProductProvider);
  final originalDescription = product.description ?? '';
  final controller = TextEditingController(text: originalDescription);
  final historyFuture = ref
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
      var selectedFilter = HistoryFilter.latest;
      return StatefulBuilder(
        builder: (context, setState) {
          final sortedHistory = sortHistoryEntries(history, selectedFilter);
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
                      DropdownButton<HistoryFilter>(
                        value: selectedFilter,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            selectedFilter = value;
                          });
                        },
                        underline: const SizedBox.shrink(),
                        items: HistoryFilter.values
                            .map(
                              (filter) => DropdownMenuItem<HistoryFilter>(
                                value: filter,
                                child: Text(filter.label),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: history.isEmpty
                        ? const Center(child: Text('No history available.'))
                        : ListView.builder(
                            itemCount: sortedHistory.length,
                            itemBuilder: (context, index) {
                              final entry = sortedHistory[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        offset: const Offset(4, 4),
                                        blurRadius: 6,
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        offset: const Offset(-4, -4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    title: Text(
                                        '£ ${entry.bonus.toStringAsFixed(0)}'),
                                    subtitle: Text(
                                        DateFormat.yMMMd().format(entry.date)),
                                  ),
                                ),
                                child: ListTile(
                                  dense: true,
                                  title: Text(
                                      '£ ${entry.bonus.toStringAsFixed(0)}'),
                                  subtitle: Text(
                                      DateFormat.yMMMd().format(entry.date)),
                                ),
                              ),
                            );
                          },
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
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      if (!isEditing)
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade600),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Close'),
                        ),
                      if (isEditing)
                        ElevatedButton(
                          onPressed: () async {
                            final updated =
                                product.copyWith(description: controller.text);
                            await ref
                                .read(productInfoProvider.notifier)
                                .editProductInfo(updated);
                            await ref
                                .read(lastSelectedProductProvider.notifier)
                                .saveSelectedProduct(updated);
                            ref.read(focusedProductProvider.notifier).state =
                                updated;
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
