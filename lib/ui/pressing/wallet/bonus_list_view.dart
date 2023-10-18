import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../providers/target_check_provider.dart';
import '../../../providers/wallet_provider.dart';
import 'add_bonus_list_item.dart';
import 'bonus_list.dart';

class BonusListView extends HookConsumerWidget {
  final List<Map<String, dynamic>> selectedEvents;
  final DateTime selectedDate;
  final String userId;
  final Function onDelete;
  final Function(Map<String, dynamic>) onAdd;


  const BonusListView({super.key,
    required this.selectedEvents,
    required this.selectedDate,
    required this.userId,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);
    ref.watch(userBonusNotifierProvider);

    // Fetch bonuses on initial render
    useEffect(() {
      userBonusNotifier.fetchUserBonuses(userId);
      return null;
    }, const []);


    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: selectedEvents.length + 1, // Add 1 for the AddBonusListItem
      itemBuilder: (context, index) {
        // If the index is the last item, return the AddBonusListItem
        if (index == selectedEvents.length) {
          return AddBonusListItem(
            onAdd: onAdd,
            selectedDate: selectedDate,
            userId: userId,
          );
        }
        // Otherwise, render the BonusListItem
        final event = selectedEvents[index];
        ref.watch(userBonusNotifierProvider);
        return Dismissible(
          key: Key(event['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              onDelete(index,0);
              await ref.read(userBonusNotifierProvider.notifier).deleteUserBonus(event['id'], userId);
              await ref.read(targetRatioProvider(userId).notifier).init();
              return true;
            }
            return false;
          },
          secondaryBackground: ClipRRect(
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(33.0),
                bottomRight: Radius.circular(33.0)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(33.0),
                    bottomRight: Radius.circular(33.0)),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.red, Colors.deepPurple.shade900],
                ),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),
          child: BonusListItem(
            date: selectedDate,
            index: index,
            event: event,
            userId: userId,
            onDelete: onDelete,
            parentIndex: index,
          ),
        );
      },
    );
  }
}

