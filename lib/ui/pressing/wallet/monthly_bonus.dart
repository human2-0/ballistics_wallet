import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyBonus extends ConsumerWidget {
  const MonthlyBonus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonuses = ref.watch(userBonusNotifierProvider);
    var monthlyBonus = 0.0;

    // Get dates for the range
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    // Check the current date to set the date range
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month , 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 18);
      endDate = DateTime(now.year, now.month, 18);
    }

    // Iterate over all bonuses
    for (final entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if ((date.compareTo(startDate) >= 0) && (date.compareTo(endDate) <= 0)) {
        // If the date is within range, sum up the bonuses
        for (final bonus in bonuses) {
          monthlyBonus += bonus['bonus'] ?? 0;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(33)),
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
                  'Total bonus\n £${formatDouble(monthlyBonus)}',
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
    );
  }
}
