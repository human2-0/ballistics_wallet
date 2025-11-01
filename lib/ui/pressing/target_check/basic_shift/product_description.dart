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
                      minLines: 3,
                      autofocus: isEditing,
                      textInputAction: TextInputAction.newline,
                      readOnly: !isEditing,
                      maxLength: 400,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: isEditing
                            ? 'Add tips, tricks, sweet‑spot powder amounts, or anything else helpful…'
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.10),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.75), width: 1.4),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        counterText: '${controller.text.length}/400',
                        counterStyle: Theme.of(context).textTheme.labelSmall,
                        suffixIcon: isEditing
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close),
                                    onPressed: controller.clear,
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: 8),
                    _DescriptionToolbar(
                      onInsert: (s) {
                        final sel = controller.selection;
                        if (!sel.isValid) {
                          controller..text += s
                          ..selection = TextSelection.collapsed(offset: controller.text.length);
                        } else {
                          final newText = controller.text.replaceRange(sel.start, sel.end, s);
                          final newOffset = sel.start + s.length;
                          controller.value = controller.value.copyWith(
                            text: newText,
                            selection: TextSelection.collapsed(offset: newOffset),
                            composing: TextRange.empty,
                          );
                        }
                      },
                    ),
                  ],
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
                    child: sortedHistory.isEmpty
                        ? const Center(child: Text('No history available.'))
                        : ListView.separated(
                            itemCount: sortedHistory.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final entry = sortedHistory[index];
                              return _HistoryTile(
                                date: entry.date,
                                bonus: entry.bonus,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.date, required this.bonus});
  final DateTime date;
  final double bonus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final divider = theme.dividerColor.withValues(alpha: 0.20);
    final primary = theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // Amount pill (compact, high contrast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.45)),
              ),
              child: Text(
                '£ ${bonus.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Date, subtle
            Expanded(
              child: Text(
                DateFormat.yMMMd().format(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionToolbar extends StatelessWidget {
  const _DescriptionToolbar({required this.onInsert});
  final void Function(String text) onInsert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipStyle = theme.textTheme.labelSmall;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        const _QuickChip(label: '• bullet', insert: '• '),
        const _QuickChip(label: 'Tip:', insert: 'Tip: '),
        const _QuickChip(label: 'Note:', insert: 'Note: '),
      ].map((c) => ActionChip(
            label: Text(c.label, style: chipStyle),
            onPressed: () => onInsert(c.insert),
          )).toList(),
    );
  }
}

class _QuickChip {
  const _QuickChip({required this.label, required this.insert});
  final String label;
  final String insert;
}
