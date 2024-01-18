import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/add_bonus_list_item.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BonusListView extends HookConsumerWidget {


  const BonusListView({required this.selectedEvents, required this.selectedDate, required this.userId, required this.onDelete, required this.onAdd, super.key,
  });
  final List<Map<String, dynamic>> selectedEvents;
  final DateTime selectedDate;
  final String userId;
  final Function onDelete;
  final void Function(Map<String, dynamic>) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);
    ref.watch(userBonusNotifierProvider);

    // Fetch bonuses on initial render
    useEffect(() {
      Future.microtask(() async => userBonusNotifier.fetchUserBonuses(userId));
      return null;
    }, const [],);


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
                topRight: Radius.circular(33),
                bottomRight: Radius.circular(33),),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(33),
                    bottomRight: Radius.circular(33),),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.red, Colors.deepPurple.shade900],
                ),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
