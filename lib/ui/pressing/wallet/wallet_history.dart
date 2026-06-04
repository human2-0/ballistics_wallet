import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/monthly_historical_data.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
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
    final products = ref.watch(productInfoProvider);
    final months =
        buildMonthlyHistoricalData(
          bonusInfo: bonusInfo,
          hourlyRate: hourlyRate,
        ).where((month) => month.hasData).toList().reversed.toList();
    final weightStats = _buildHistoryWeightStats(
      months: months,
      bonusInfo: bonusInfo,
      products: products,
    );

    if (months.isEmpty) {
      return const _EmptyHistory();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryOverview(months: months, weightStats: weightStats),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: months.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = months[index];
                return _HistoryMonthTile(
                  data: data,
                  weightStats: weightStats[data.month],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryOverview extends StatelessWidget {
  const _HistoryOverview({required this.months, required this.weightStats});

  final List<MonthlyData> months;
  final Map<String, _HistoryWeightStats> weightStats;

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
    final totalKg = weightStats.values.fold<double>(
      0,
      (sum, stats) => sum + stats.totalKg,
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
          Row(
            children: [
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Income',
                  value: '£${formatDouble(totalIncome)}',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Hours',
                  value: formatDouble(totalHours),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Bonus',
                  value: '£${formatDouble(totalBonus)}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Moved',
                  value: '${formatDouble(totalKg)} kg',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryMonthTile extends StatefulWidget {
  const _HistoryMonthTile({required this.data, required this.weightStats});

  final MonthlyData data;
  final _HistoryWeightStats? weightStats;

  @override
  State<_HistoryMonthTile> createState() => _HistoryMonthTileState();
}

class _HistoryMonthTileState extends State<_HistoryMonthTile> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.data;
    final stats = widget.weightStats ?? const _HistoryWeightStats.empty();
    final hasMovement = stats.products.isNotEmpty;
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
          Row(
            children: [
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Hour pay',
                  value: '£${formatDouble(data.hourPay)}',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Hours',
                  value: formatDouble(data.totalHours),
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Bonus',
                  value: '£${formatDouble(data.totalBonus)}',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _SummaryPill.compact(
                  label: 'Moved',
                  value: '${formatDouble(stats.totalKg)} kg',
                  color: Colors.blue,
                ),
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
          if (hasMovement) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _showDetails = !_showDetails);
                },
                icon: Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(_showDetails ? 'Hide details' : 'Details'),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _ProductWeightBreakdown(data: data, stats: stats),
              crossFadeState:
                  _showDetails
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductWeightBreakdown extends StatelessWidget {
  const _ProductWeightBreakdown({required this.data, required this.stats});

  final MonthlyData data;
  final _HistoryWeightStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = stats.products.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product movement',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _formatRange(data.bonusStart, data.bonusEnd),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ...products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${product.units} units • ${formatDouble(product.kg)} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  }) : compact = false;

  const _SummaryPill.compact({
    required this.label,
    required this.value,
    required this.color,
  }) : compact = true;

  final String label;
  final String value;
  final MaterialColor color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding:
          compact
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        color: color[50]!.withValues(alpha: 0.82),
        border: Border.all(color: color[200]!.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color[900],
              fontSize: compact ? 10 : null,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 2 : 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 11 : null,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (compact) return pill;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 170),
      child: pill,
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
  Widget build(BuildContext context) => Row(
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
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

Map<String, _HistoryWeightStats> _buildHistoryWeightStats({
  required List<MonthlyData> months,
  required List<BonusInfo> bonusInfo,
  required List<ProductInfo> products,
}) {
  final productsByKey = {
    for (final product in products) _productKey(product.productName): product,
  };
  final statsByMonth = <String, _HistoryWeightStats>{};

  for (final month in months) {
    final bonusStart = month.bonusStart;
    final bonusEnd = month.bonusEnd;
    if (bonusStart == null || bonusEnd == null) {
      statsByMonth[month.month] = const _HistoryWeightStats.empty();
      continue;
    }

    final builders = <String, _ProductWeightBuilder>{};
    for (final info in bonusInfo) {
      final date = DateTime(info.date.year, info.date.month, info.date.day);
      if (date.isBefore(bonusStart) || date.isAfter(bonusEnd)) continue;

      for (final produced in info.produced) {
        final key = _productKey(produced.productName);
        if (key.isEmpty || produced.amount <= 0) continue;

        final product = productsByKey[key];
        final gramsPerUnit = product?.finalProductWeightGrams ?? 0;
        final displayName =
            (product?.productName.trim().isNotEmpty ?? false)
                ? product!.productName
                : produced.productName;

        builders
            .putIfAbsent(key, () => _ProductWeightBuilder(displayName))
            .add(
              units: produced.amount,
              kg: (produced.amount * gramsPerUnit) / 1000,
            );
      }
    }

    final productStats =
        builders.values.map((builder) => builder.build()).toList()
          ..sort((left, right) {
            final kgCompare = right.kg.compareTo(left.kg);
            if (kgCompare != 0) return kgCompare;
            return right.units.compareTo(left.units);
          });
    statsByMonth[month.month] = _HistoryWeightStats(productStats);
  }

  return statsByMonth;
}

String _productKey(String value) => value.toLowerCase().trim();

class _HistoryWeightStats {
  const _HistoryWeightStats(this.products);

  const _HistoryWeightStats.empty() : products = const [];

  final List<_ProductWeightStats> products;

  double get totalKg =>
      products.fold<double>(0, (sum, product) => sum + product.kg);
}

class _ProductWeightStats {
  const _ProductWeightStats({
    required this.name,
    required this.units,
    required this.kg,
  });

  final String name;
  final int units;
  final double kg;
}

class _ProductWeightBuilder {
  _ProductWeightBuilder(this.name);

  final String name;
  int units = 0;
  double kg = 0;

  void add({required int units, required double kg}) {
    this.units += units;
    this.kg += kg;
  }

  _ProductWeightStats build() =>
      _ProductWeightStats(name: name, units: units, kg: kg);
}
