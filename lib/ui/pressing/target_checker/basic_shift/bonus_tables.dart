import 'package:ballistics_wallet_flutter/custom_widgets/animated_tile.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
// Import the PressingRepository
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/custom_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BonusTable extends ConsumerStatefulWidget {
  const BonusTable({super.key});

  @override
  BonusTableState createState() => BonusTableState();
}

class BonusTableState extends ConsumerState {
  @override
  Widget build(BuildContext context) {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    final targetRatio = ref.watch(targetRatioProvider(userId));
    final userData = ref.watch(userNotifierProvider);
    final overtimeRatio = ref.watch(overtimeRatioProvider);
    final overtimeHours = ref.watch(overtimeWorkingHoursState);
    final workingHours = userData.workingHours ?? 0.0;
    final allowance = ref.watch(allowanceProvider);

    return Stack(
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: Future.microtask(
              () async => ref.read(pressingRepositoryProvider).getBonuses(),),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Text('An error occurred');
            } else {
              final bonuses = snapshot.data!;
              final stableTarget = ref.watch(targetProvider);
              var target = ref.watch(targetProvider) * (1 - targetRatio);
              if (targetRatio == 0.0) {
                final allowanceCheck = (workingHours - allowance) / 7;
                if (allowanceCheck > 0) {
                  target = (target * allowanceCheck).ceilToDouble();
                }
              }

              // Sort the keys in ascending order
              final sortedKeys = bonuses.keys.toList();

              // Generate list of widgets
              final listItems = <Widget>[];

              if (target > 0) {
                listItems.add(
                  AnimatedTile(
                    target: target.ceil(),
                    onLongPressComplete: () {
                      // Actions to perform after the long press completes
                      // For example, navigating away or showing a message
                      Future.microtask(() async => saveToWallet(
                          context: context,
                          ref: ref,
                          amountPressed: target.ceil(),
                          mounted: mounted,),);
                    },
                  ),
                );
              }

              listItems.addAll(
                sortedKeys.map((key) {
                  final bonus = (bonuses[key] as num).toDouble() *
                      (((overtimeHours ?? 0) > 0)
                          ? ((overtimeHours ?? 0) / 7)
                          : (workingHours - allowance) / 7.0);
                  final requiredPercentage = double.parse(key) -
                      ((overtimeRatio > 0.0) ? overtimeRatio : targetRatio) *
                          100;
                  final allowanceCheck = (workingHours - allowance) / 7;

                  final requiredAmount = ((requiredPercentage *
                              (allowanceCheck > 0
                                  ? (stableTarget * allowanceCheck).ceil()
                                  : stableTarget)) /
                          100)
                      .ceil();

                  if (requiredAmount > 0) {
                    return BonusAnimatedTile(
                      bonus: bonus,
                      requiredAmount: requiredAmount,
                      onLongPressComplete: () {
                        // Define what happens when the long press completes, e.g., saving to wallet
                        Future.microtask(() async => saveToWallet(
                            context: context,
                            ref: ref,
                            amountPressed: requiredAmount,
                            mounted: mounted,),);
                      },
                    );
                  }
                  return null;
                }).whereType<Widget>(),
              );

              return ListWheelScrollView(
                diameterRatio: 1.5,
                itemExtent: MediaQuery.of(context).size.height * 0.25,
                children: listItems,
              );
            }
          },
        ),
        Positioned(
          top: 32,
          right: 0,
          child: FloatingActionButton(
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.red,
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
