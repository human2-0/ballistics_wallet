import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Displays paycheck-month income history for the wallet.
class WalletHistory extends ConsumerWidget {
  /// Creates the wallet history widget.
  const WalletHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonusInfo = ref.watch(
      bonusInfoListProvider.select((state) => state.bonusInfo),
    );
    final hourlyRate =
        ref.watch(userNotifierProvider.select((state) => state.hourlyRate)) ??
        0;
    final months =
        buildMonthlyHistoricalData(
          bonusInfo: bonusInfo,
          hourlyRate: hourlyRate,
        ).where((month) => month.hasData).toList().reversed.toList();

    if (months.isEmpty) {
      return const _EmptyHistory();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryOverview(months: months),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: months.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _HistoryMonthTile(data: months[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryOverview extends StatelessWidget {
  const _HistoryOverview({required this.months});

  final List<MonthlyData> months;

  @override
  Widget build(BuildContext context) {
    final totalIncome = months.fold<double>(
      0,
      (sum, month) => sum + month.totalIncome,
    );
    final totalHours = months.fold<double>(
      0,
      (sum, month) => sum + month.totalHours,
    );
    final totalBonus = months.fold<double>(
      0,
      (sum, month) => sum + month.totalBonus,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.orange[800]),
              const SizedBox(width: 8),
              Text(
                'History',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: 'Income',
                value: '£${formatDouble(totalIncome)}',
                color: Colors.amber,
              ),
              _SummaryPill(
                label: 'Hours',
                value: formatDouble(totalHours),
                color: Colors.purple,
              ),
              _SummaryPill(
                label: 'Bonus',
                value: '£${formatDouble(totalBonus)}',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMonthTile extends StatelessWidget {
  const _HistoryMonthTile({required this.data});

  final MonthlyData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[50]!.withValues(alpha: 0.9),
            Colors.white,
            Colors.green[50]!.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.month,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '£${formatDouble(data.totalIncome)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: 'Hour pay',
                value: '£${formatDouble(data.hourPay)}',
                color: Colors.amber,
              ),
              _SummaryPill(
                label: 'Hours',
                value: formatDouble(data.totalHours),
                color: Colors.purple,
              ),
              _SummaryPill(
                label: 'Bonus',
                value: '£${formatDouble(data.totalBonus)}',
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RangeLine(
            color: Colors.purple,
            label: 'Hours',
            value: _formatRange(data.hoursStart, data.hoursEnd),
          ),
          const SizedBox(height: 6),
          _RangeLine(
            color: Colors.green,
            label: 'Bonus',
            value: _formatRange(data.bonusStart, data.bonusEnd),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color[50]!.withValues(alpha: 0.82),
          border: Border.all(color: color[200]!.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color[900],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeLine extends StatelessWidget {
  const _RangeLine({
    required this.color,
    required this.label,
    required this.value,
  });

  final MaterialColor color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color[400],
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.78),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.orange[800], size: 32),
            const SizedBox(height: 8),
            Text(
              'No history yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRange(DateTime? start, DateTime? end) {
  if (start == null || end == null) {
    return '';
  }
  final startFormat = DateFormat(
    start.year == end.year ? 'd MMM' : 'd MMM yyyy',
  );
  final endFormat = DateFormat('d MMM yyyy');
  return '${startFormat.format(start)} - ${endFormat.format(end)}';
}
