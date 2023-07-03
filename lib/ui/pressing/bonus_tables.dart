import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/utilities.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet_pressing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:ballistics_wallet_flutter/providers/auth_provider.dart'; // Import the PressingRepository

class BonusTableAlive extends StatefulWidget {
  const BonusTableAlive({Key? key}) : super(key: key);

  @override
  BonusTableAliveState createState() => BonusTableAliveState();
}

class BonusTableAliveState extends State<BonusTableAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BonusTable();
  }
}

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



    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.orange[100]!, Colors.orange[50]!],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<Map<String, dynamic>>(
            future: ref.read(pressingRepositoryProvider).getBonuses(),
            builder: (context, snapshot) {
              print('builder check');
              print(overtimeHours);


              final bonuses = snapshot.data!;
              final int stableTarget = ref.watch(targetProvider);
              print('stable target');
              print(stableTarget);
              final target = ref.watch(targetProvider) *
                  (1 - ((overtimeRatio > 0.0) ? (overtimeRatio) : targetRatio));
              print(target);// Recalculate target

              // Sort the keys in ascending order
              final sortedKeys = bonuses.keys.toList()
                ..sort((a, b) => double.parse(a).compareTo(double.parse(b)));

              // Generate table rows
              List<DataRow> tableRows = [];

              // Add minimum row only if target value is positive
              if (target > 0) {
                tableRows.add(
                  DataRow(
                      color: MaterialStateProperty.all(Colors.orange[200]),
                      cells: [
                        const DataCell(Center(child: Text('Minimum'))),
                        DataCell(Center(child: Text('${target.toInt()}'))),
                      ]),
                );
              }

              // Add remaining rows
              tableRows.addAll(sortedKeys.map((key) {
                final bonus = (bonuses[key] as num).toDouble() * (((overtimeHours ?? 0) > 0) ? ((overtimeHours ?? 0) / 7) : (((workingHours.toDouble()) - allowance.toDouble()) ) / 7.0);
                final requiredPercentage =
                    double.parse(key) - ((overtimeRatio > 0.0) ? overtimeRatio : targetRatio) * 100;
                final requiredAmount =
                    ((requiredPercentage * stableTarget) / 100).ceil();

                // Skip rows where requiredAmount is less than or equal to zero
                if (requiredAmount <= 0) {
                  return null;
                }

                return DataRow(cells: [
                  DataCell(Center(child: Text('£${formatDouble(bonus)}'))),
                  DataCell(Center(child: Text('$requiredAmount'))),
                ]);
              }).whereType<DataRow>());

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Center(child: Text('Target'))),
                      DataColumn(label: Center(child: Text('Required Amount'))),
                    ],
                    rows: tableRows,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
