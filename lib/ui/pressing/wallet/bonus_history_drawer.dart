import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class BonusHistoryDrawer extends HookConsumerWidget {

  const BonusHistoryDrawer({required this.onNotification, super.key});
  final void Function(ScrollNotification) onNotification;

  num calculateTotalBonus(Map<DateTime, List<dynamic>> userBonuses,
      DateTime startDate, DateTime endDate) {
    num totalBonus = 0;

    // Iterate over all bonuses
    for (final entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        // If the date is within range, sum up the bonuses
        for (final bonus in bonuses) {
          totalBonus += bonus['bonus'] as num? ?? 0;
        }
      }
    }

    return totalBonus;
  }

  num calculateTotalHours(Map<DateTime, List<dynamic>> userBonuses,
      DateTime startDate, DateTime endDate) {
    num totalHours = 0;

    // Iterate over all bonuses
    for (final entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        // If the date is within range, sum up the hours
        for (final bonus in bonuses) {
          totalHours += bonus['workingHours'] as num? ?? 0;
        }
      }
    }

    return totalHours;
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonuses = ref.watch(userBonusNotifierProvider);
    final now = DateTime.now();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        onNotification(notification);
        return true;
      },
      child: Drawer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: const [0.1, 0.3, 0.7, 0.95],
              colors: [
                Colors.orange[700]!.withOpacity(0.9),
                Colors.orange[500]!.withOpacity(0.8),
                Colors.brown.withOpacity(0.65),
                Colors.blueGrey.withOpacity(0.45),
              ],
            ),
          ),
          child: ListView.separated(
            itemCount: 12,
            separatorBuilder: (context, index) =>
            const SizedBox(height: 8), // adds space between the items
            itemBuilder: (context, index) {
              final monthStart = DateTime(now.year, now.month - index, 19);
              final monthEnd = DateTime(now.year, now.month - index + 1, 18);

              final totalBonusForMonth =
              calculateTotalBonus(bonuses, monthStart, monthEnd);

              final totalHoursForMonth = calculateTotalHours(bonuses, monthStart, monthEnd);

              final period =
                  '${DateFormat('MMMM yyyy').format(monthStart)} - ${DateFormat('MMMM yyyy').format(monthEnd)}';

              return Padding(
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(33),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.6),
                        offset: const Offset(8, 8),
                        blurRadius: 10,
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.4),
                        offset: const Offset(-4, -4),
                        blurRadius: 10,
                        spreadRadius: -4,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.1, 0.6, 0.8, 0.95],
                      colors: [
                        Colors.orange[700]!.withOpacity(0.9),
                        Colors.orange[500]!.withOpacity(0.8),
                        Colors.orange[100]!.withOpacity(0.65),
                        Colors.white.withOpacity(0.45),
                      ],
                    ),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    title: Text(
                      period,
                      style: const TextStyle(
                          color: Colors.white), // adjusts the text color
                    ),
                    subtitle: Text(
                      'Total bonus: £$totalBonusForMonth\nTotal Hours: $totalHoursForMonth ',
                      style: const TextStyle(
                          color: Colors.white70), // adjusts the subtitle color
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
