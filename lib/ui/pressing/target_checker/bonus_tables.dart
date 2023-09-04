
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';

import '../split_check/split_check.dart'; // Import the PressingRepository

class BonusTable extends ConsumerWidget {
  const BonusTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId = ref.read(authRepositoryProvider).currentUserId;
    double targetRatio = ref.watch(targetRatioProvider(userId));
    final userData = ref.watch(userNotifierProvider);
    final overtimeRatio = ref.watch(overtimeRatioProvider);
    final overtimeHours = ref.watch(overtimeWorkingHoursState);
    final workingHours = userData.workingHours ?? 0.0;
    final allowance = ref.watch(allowanceProvider);
    print('allowance here $allowance');
    double allowanceCheck = 0;

    return Stack(
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: ref.read(pressingRepositoryProvider).getBonuses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              print('Error: ${snapshot.error}');
              return const Text('An error occurred');
            } else {
              final bonuses = snapshot.data!;
              final int stableTarget = ref.watch(targetProvider);
              double target = ref.watch(targetProvider) * (1 - targetRatio);
              if (targetRatio == 0.0) {
                double allowanceCheck = (workingHours - allowance) / 7;
                print(allowanceCheck);
                if (allowanceCheck > 0) {
                  target = target * allowanceCheck;
                }
              }

              // Sort the keys in ascending order
              final sortedKeys = bonuses.keys.toList();

              // Generate list of widgets
              List<Widget> listItems = [];

              if (target > 0) {
                listItems.add(
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SplitCheck(requiredAmount: target.ceil()),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.orange[200]!, Colors.white],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            color: Colors.orange.withOpacity(0.5),
                            gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Colors.orange[200]!, Colors.white],
                          ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 3,
                                offset: const Offset(2, 2), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Column(

                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Minimum',
                                style: TextStyle(fontSize: 16.0, color: Colors.black54),
                              ),
                              Text(
                                '${target.ceil()}',
                                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              listItems.addAll(sortedKeys.map((key) {
                final bonus = (bonuses[key] as num).toDouble() *
                    (((overtimeHours ?? 0) > 0)
                        ? ((overtimeHours ?? 0) / 7)
                        : (((workingHours.toDouble()) -
                        allowance.toDouble())) / 7.0);
                final requiredPercentage =
                    double.parse(key) - ((overtimeRatio > 0.0)
                        ? overtimeRatio
                        : targetRatio) * 100;
                print(requiredPercentage);
                double allowanceCheck = (workingHours - allowance) / 7;

                final requiredAmount = ((requiredPercentage * (allowanceCheck > 0 ? stableTarget * allowanceCheck : stableTarget)) / 100).round();

                if (requiredAmount > 0) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SplitCheck(requiredAmount: requiredAmount),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      height: MediaQuery.of(context).size.height * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Colors.orange[200]!, Colors.white],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 5,
                            blurRadius: 7,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: Colors.orange.withOpacity(0.5),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.orange[200]!, Colors.white],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 3,
                                      offset: const Offset(2, 2), // changes position of shadow
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'to earn',
                                      style: TextStyle(fontSize: 16.0, color: Colors.black54),
                                    ),
                                    Text(
                                    '£${formatDouble(bonus)}',
                                    style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                                  ),]
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.0),
                                  color: Colors.orange.withOpacity(0.5),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Colors.orange[200]!, Colors.white],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 3,
                                      offset: const Offset(2, 2), // changes position of shadow
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$requiredAmount',
                                      style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'more to do',
                                      style: TextStyle(fontSize: 16.0, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return null;
                }
              }).whereType<Widget>());


              return ListWheelScrollView(
                diameterRatio: 1.5,
                itemExtent: MediaQuery.of(context).size.height * 0.25,
                children: listItems,
              );
            }
          },
        ),
        Positioned(
          top: 32.0,
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

final updateAvailableItemsProvider = FutureProvider.autoDispose<void>((ref) async {
  final String userId = ref.read(authRepositoryProvider).currentUserId;
  final userData = ref.read(userNotifierProvider);
  final overtimeRatio = ref.watch(overtimeRatioProvider);
  final overtimeHours = ref.watch(overtimeWorkingHoursState);
  final workingHours = userData.workingHours ?? 0.0;
  final allowance = ref.watch(allowanceProvider);
  final bonuses = await ref.read(pressingRepositoryProvider).getBonuses();
  final int stableTarget = ref.watch(targetProvider);
  final targetRatio = ref.watch(targetRatioProvider(userId));
  final target = ref.watch(targetProvider) *
      (1 - ((overtimeRatio > 0.0) ? overtimeRatio : targetRatio));
  final sortedKeys = bonuses.keys.toList()
    ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));

  List<Widget> listItems = [];

  for (String key in sortedKeys) {
    final bonus = (bonuses[key] as num).toDouble() *
        (((overtimeHours ?? 0) > 0)
            ? ((overtimeHours ?? 0) / 7)
            : (((workingHours.toDouble()) - allowance.toDouble())) / 7.0);
    final requiredPercentage =
        double.parse(key) - ((overtimeRatio > 0.0)
            ? overtimeRatio
            : targetRatio * 100);
    final requiredAmount = ((requiredPercentage * stableTarget) / 100).ceil();

    if (requiredAmount > 0) {
      listItems.add(Container());
    }
  }

  ref.read(availableItemsProvider.notifier).state = listItems.length;
});

final availableItemsProvider = StateProvider<int>((ref) => 0);

