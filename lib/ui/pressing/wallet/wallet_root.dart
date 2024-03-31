import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_info_list.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/date_picker.dart';
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
    return Scaffold(
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
                    width: MediaQuery.of(context).size.width * 0.40,
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
                            Colors.orange[400]!.withOpacity(0.6),
                            Colors.orange[300]!,
                            Colors.orange[200]!,
                            Colors.orange[100]!,
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
                              'Total hours\n ${ref.read(bonusInfoListProvider.notifier).getTotalWorkingHours()}',
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
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(33)),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.brown,
                            Colors.orangeAccent,
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
                              'Total bonus\n £${ref.read(bonusInfoListProvider.notifier).getTotalBonus()}',
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
