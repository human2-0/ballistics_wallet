import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/add_item_bottom_sheet.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/edit_item_bottom_sheet.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/new_wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BonusInfoList extends ConsumerStatefulWidget {
  const BonusInfoList({super.key});
  @override
  _BonusInfoListState createState() => _BonusInfoListState();
}

class _BonusInfoListState extends ConsumerState<BonusInfoList> {
  @override
  Widget build(BuildContext context) {
    final bonusInfoList = ref.watch(bonusInfoListProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    if (bonusInfoList
        .where((info) => isSameDay(info.date, selectedDate))
        .isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(25)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.5, 0.7, 0.9],
                colors: [
                  Colors.orange[300]!.withOpacity(0.4),
                  Colors.orange[200]!,
                  Colors.orange[100]!,
                  Colors.orange[100]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange[500]!.withOpacity(0.4),
                  offset: const Offset(-10, -10),
                  blurRadius: 10,
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  offset: const Offset(5, 5),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                await showModalBottomSheet<Widget>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => AddBonusInfoModal(context: context),
                );
              },
            ),
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: bonusInfoList
            .where((info) => isSameDay(info.date, selectedDate))
            .length,
        itemBuilder: (context, index) {
          final dailyBonusInfo = bonusInfoList
              .where((info) => isSameDay(info.date, selectedDate))
              .toList();
          final info = dailyBonusInfo[index];

          return Dismissible(
            key: Key(
              index.toString(),
            ), // Ensure to provide a unique key for each item
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
                      Colors.red[50]!.withOpacity(0.3),
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
              // Handle item deletion
            },
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (context) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete'),
                        onTap: () => Navigator.pop(context, 'delete'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Edit'),
                        onTap: () => Navigator.pop(context, 'edit'),
                      ),
                      ListTile(
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
                    WidgetsBinding.instance
                        .addPostFrameCallback((timeStamp) async {
                      await showEditModal(
                        context,
                        ref,
                        info,
                        index,
                      );
                    });

                    return false; // Return false to not dismiss the item on edit
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
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(33)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.1, 0.5, 0.7, 0.9],
                    colors: [
                      Colors.orange[50]!.withOpacity(0.4),
                      Colors.orange[100]!,
                      Colors.orange[200]!,
                      Colors.orange[300]!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange[500]!.withOpacity(0.6),
                      offset: const Offset(10, 10),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      offset: const Offset(-5, -5),
                      blurRadius: 15,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(
                            8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(33),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.5, 0.7, 0.9],
                              colors: [
                                Colors.orange[300]!.withOpacity(0.4),
                                Colors.orange[200]!,
                                Colors.orange[100]!,
                                Colors.orange[100]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange[500]!.withOpacity(0.4),
                                offset: const Offset(-10, -10),
                                blurRadius: 10,
                                spreadRadius: -5,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                offset: const Offset(5, 5),
                                blurRadius: 15,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Text(
                            '${info.workingHours} hrs',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(33),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.5, 0.7, 0.9],
                              colors: [
                                Colors.orange[300]!.withOpacity(0.4),
                                Colors.orange[200]!,
                                Colors.orange[100]!,
                                Colors.orange[100]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange[500]!.withOpacity(0.4),
                                offset: const Offset(-10, -10),
                                blurRadius: 10,
                                spreadRadius: -5,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                offset: const Offset(5, 5),
                                blurRadius: 15,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Text(
                            '£${info.bonus.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: info.produced.length,
                          itemBuilder: (context, i) {
                            final item = info.produced[i];
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(33),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: const [0.1, 0.5, 0.7, 0.9],
                                  colors: [
                                    Colors.orange[300]!.withOpacity(0.4),
                                    Colors.orange[200]!,
                                    Colors.orange[100]!,
                                    Colors.orange[100]!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange[500]!.withOpacity(0.4),
                                    offset: const Offset(-10, -10),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    offset: const Offset(5, 5),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.6),
                                    offset: const Offset(15, 0),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${item.productName} - ${item.amount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }
}
