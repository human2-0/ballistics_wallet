import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_info_list.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/date_picker.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletRoot extends ConsumerStatefulWidget {
  const WalletRoot({required this.onNotification, super.key});
  final void Function(ScrollNotification) onNotification;
  @override
  ConsumerState<WalletRoot> createState() => _WalletRootState();
}

class _WalletRootState extends ConsumerState<WalletRoot> {
  @override
  Widget build(BuildContext context) {
    ref.watch(bonusInfoListProvider);
    final userState = ref.watch(userNotifierProvider);
    final totalBonus = ref.read(bonusInfoListProvider.notifier).getTotalBonus();
    final totalHours =
        ref.read(bonusInfoListProvider.notifier).getTotalWorkingHours();
    final totalSalary = totalBonus + (totalHours * userState.hourlyRate!);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            iconSize: 40,
            icon: const Icon(Icons.history),
            onPressed: () async => showModalBottomSheet(
              context: context,
              builder: (context) {
                return SizedBox(
                  height: 400,
                  child: FutureBuilder<List<MonthlyData>>(
                    future: ref
                        .read(bonusInfoListProvider.notifier)
                        .getHistoricalMonthlyData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData) {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data![index];
                            return ListTile(
                              title: Text(data.month),
                              subtitle: Text(
                                  'Hours: ${data.totalHours}, Bonus: ${data.totalBonus}',),
                            );
                          },
                        );
                      } else {
                        return const Center(
                            child: Text('No historical data found'),);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          widget.onNotification(notification);
          return true;
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.30,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(33)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.1, 0.6, 0.8, 0.9],
                          colors: [
                            Colors.purple[400]!.withOpacity(0.6),
                            Colors.purple[300]!,
                            Colors.purple[200]!,
                            Colors.purple[100]!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Total hours\n ${formatDouble(totalHours)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.30,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(33)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.1, 0.6, 0.8, 1],
                          colors: [
                            Colors.yellow[800]!.withOpacity(0.6),
                            Colors.yellow[700]!,
                            Colors.yellow[600]!,
                            Colors.yellow[300]!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Total salary £${formatDouble(totalSalary)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.30,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(33)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green[400]!.withOpacity(0.6),
                            Colors.green[300]!,
                            Colors.green[200]!,
                            Colors.green[100]!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: Text(
                              'Total bonus\n £${formatDouble(totalBonus)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.all(
                    Radius.circular(33),
                  ),
                ),
                child: const DatePickerCalendar(),
              ),
            ),
            const BonusInfoList(),
          ],
        ),
      ),
      endDrawer: Container(),
    );
  }
}
