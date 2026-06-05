import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/add_bonus_bottom_sheet.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/edit_bonus_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BonusInfoList extends ConsumerStatefulWidget {
  const BonusInfoList({super.key});

  @override
  ConsumerState<BonusInfoList> createState() => _BonusInfoListState();
}

class _BonusInfoListState extends ConsumerState<BonusInfoList> {
  @override
  Widget build(BuildContext context) {
    bool isSameDay(DateTime? date1, DateTime? date2) =>
        date1?.year == date2?.year &&
        date1?.month == date2?.month &&
        date1?.day == date2?.day;

    final bonusInfoList = ref.watch(bonusInfoListProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Check if we have no items for that day
    final dayItems =
        bonusInfoList.bonusInfo
            .where((info) => isSameDay(info.date, selectedDate))
            .toList();

    if (dayItems.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: getCustomBoxDecoration(Colors.orange),
              child: IconButton(
                key: const Key('addBonusIcon'), // <--- key for tests
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: () async {
                  // Use context.push or context.showModalBottomSheet via GoRouter
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => const AddBonusInfoModal(),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: dayItems.length,
      itemBuilder: (context, index) {
        final info = dayItems[index];

        // Create a unique key for the Dismissible row.
        final dismissKey = Key('dismissible_${info.id}');

        return Dismissible(
          key: dismissKey,
          background: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  stops: const [0.1, 0.3, 0.7, 0.9],
                  colors: [
                    Colors.red[50]!.withValues(alpha: 0.3),
                    Colors.red[100]!,
                    Colors.red,
                    Colors.red[600]!,
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(33)),
              ),
              alignment: Alignment.centerRight,
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.white),
                  SizedBox(width: 40),
                  Icon(Icons.edit, color: Colors.white),
                ],
              ),
            ),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            // Potentially handle item deletion
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              final action = await showModalBottomSheet<String>(
                context: context,
                builder:
                    (context) => Wrap(
                      children: [
                        ListTile(
                          key: const Key(
                            'deleteListTile',
                          ), // <--- key for "Delete"
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(33),
                              topRight: Radius.circular(33),
                            ),
                          ),
                          tileColor: Colors.red[100],
                          iconColor: Colors.red,
                          leading: const Icon(Icons.delete),
                          title: const Text('Delete'),
                          onTap: () => Navigator.pop(context, 'delete'),
                        ),
                        ListTile(
                          key: const Key('editListTile'), // <--- key for "Edit"
                          tileColor: Colors.yellow[100],
                          iconColor: Colors.yellow[700],
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () => Navigator.pop(context, 'edit'),
                        ),
                        ListTile(
                          key: const Key(
                            'cancelListTile',
                          ), // <--- key for "Cancel"
                          leading: const Icon(Icons.cancel),
                          title: const Text('Cancel'),
                          onTap: () => Navigator.pop(context, 'cancel'),
                        ),
                      ],
                    ),
              );

              switch (action) {
                case 'delete':
                  await ref
                      .read(bonusInfoListProvider.notifier)
                      .deleteBonusInfo(info);
                  return true;
                case 'edit':
                  // Implement edit logic here, showing another modal to edit the item
                  if (!context.mounted) return false;
                  await showModalBottomSheet<Widget>(
                    context: context,
                    isScrollControlled: true,
                    builder:
                        (_) =>
                            EditBonusInfoModal(bonusInfo: info, index: index),
                  );

                  return false;
                case 'cancel':
                default:
                  // Do nothing for cancel or undefined actions
                  return false;
              }
            }
            return false;
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DecoratedBox(
              decoration: getCustomBoxDecoration(Colors.orange),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomInfoContainer(
                        text: '${info.workingHours} hrs',
                        baseColor: Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: CustomInfoContainer(
                        text: '£${info.bonus.toStringAsFixed(2)}',
                        baseColor: Colors.green,
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: info.produced.length,
                        itemBuilder: (context, i) {
                          final item = info.produced[i];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.38,
                                child: CustomInfoContainer(
                                  text: item.productName,
                                  baseColor: Colors.amber,
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.12,
                                child: CustomInfoContainer(
                                  text: '${item.amount}',
                                  baseColor: Colors.amber,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Same function as before, unchanged
BoxDecoration getCustomBoxDecoration(MaterialColor baseColor) => BoxDecoration(
  borderRadius: const BorderRadius.all(Radius.circular(33)),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.1, 0.5, 0.7, 0.9],
    colors: [
      baseColor[300]!.withValues(alpha: 0.4),
      baseColor[200]!,
      baseColor[100]!,
      baseColor[100]!,
    ],
  ),
  boxShadow: [
    BoxShadow(
      color: baseColor[500]!.withValues(alpha: 0.4),
      offset: const Offset(-10, -10),
      blurRadius: 10,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: baseColor.withValues(alpha: 0.4),
      offset: const Offset(5, 5),
      blurRadius: 15,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.6),
      offset: const Offset(15, 0),
      blurRadius: 10,
    ),
  ],
);

class CustomInfoContainer extends StatelessWidget {
  const CustomInfoContainer({
    required this.text,
    required this.baseColor,
    super.key,
  });
  final String text;
  final MaterialColor baseColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: getCustomBoxDecoration(baseColor),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.brown[900],
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
