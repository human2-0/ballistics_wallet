// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs, prefer_expression_function_bodies
// ignore_for_file: unnecessary_underscores, lines_longer_than_80_chars

import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_info_list.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/date_picker.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/wallet_history.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletRoot extends ConsumerStatefulWidget {
  const WalletRoot({super.key});

  @override
  ConsumerState<WalletRoot> createState() => _WalletRootState();
}

class _WalletRootState extends ConsumerState<WalletRoot> {
  _WalletTool _selectedTool = _WalletTool.calendar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 8,
        title: _WalletToolSelector(
          selectedTool: _selectedTool,
          onSelectionChanged: (tool) {
            setState(() => _selectedTool = tool);
          },
        ),
      ),
      backgroundColor: Colors.transparent,
      body: switch (_selectedTool) {
        _WalletTool.calendar => const _WalletCalendarTool(),
        _WalletTool.history => const WalletHistory(),
        _WalletTool.stats => const _WalletStatsTool(),
      },
    );
  }
}

enum _WalletTool { calendar, history, stats }

Widget _buildTotalsRow(BuildContext context, WalletSummary summary) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildGradientBox(
      context: context,
      title: 'Hours',
      value: formatDouble(summary.totalHours),
      colors: [
        Colors.purple[400]!.withValues(alpha: 0.4),
        Colors.purple[300]!,
        Colors.purple[200]!,
        Colors.purple[100]!,
      ],
    ),
    _buildGradientBox(
      context: context,
      title: 'Income',
      value: '£${formatDouble(summary.totalSalary)}',
      colors: [
        Colors.yellow[800]!.withValues(alpha: 0.4),
        Colors.yellow[700]!,
        Colors.yellow[600]!,
        Colors.yellow[300]!,
      ],
    ),
    _buildGradientBox(
      context: context,
      title: 'Bonus',
      value: '£${formatDouble(summary.totalBonus)}',
      colors: [
        Colors.green[400]!.withValues(alpha: 0.4),
        Colors.green[300]!,
        Colors.green[200]!,
        Colors.green[100]!,
      ],
    ),
  ],
);

Widget _buildGradientBox({
  required BuildContext context,
  required String title,
  required String value,
  required List<Color> colors,
}) => Padding(
  padding: const EdgeInsets.all(5),
  child: SizedBox(
    width: MediaQuery.of(context).size.width * 0.30,
    height: MediaQuery.of(context).size.height * 0.1,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(33)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child:
                value.isNotEmpty
                    ? Text(
                      '$title\n$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    )
                    : Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
          ),
        ),
      ),
    ),
  ),
);

class _WalletToolSelector extends StatelessWidget {
  const _WalletToolSelector({
    required this.selectedTool,
    required this.onSelectionChanged,
  });

  final _WalletTool selectedTool;
  final ValueChanged<_WalletTool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 16).clamp(320.0, 520.0);
    return SizedBox(
      width: width,
      child: SegmentedButton<_WalletTool>(
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        segments: const [
          ButtonSegment(
            value: _WalletTool.calendar,
            icon: Icon(Icons.calendar_month_outlined),
            label: Text('Calendar'),
          ),
          ButtonSegment(
            value: _WalletTool.history,
            icon: Icon(Icons.history),
            label: Text('History'),
          ),
          ButtonSegment(
            value: _WalletTool.stats,
            icon: Icon(Icons.insert_chart_outlined),
            label: Text('Stats'),
          ),
        ],
        selected: {selectedTool},
        onSelectionChanged: (selection) {
          onSelectionChanged(selection.first);
        },
      ),
    );
  }
}

class _WalletCalendarTool extends StatelessWidget {
  const _WalletCalendarTool();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer(
          builder: (context, ref, _) {
            final summary = ref.watch(walletSummaryProvider);
            return summary.when(
              data: (summary) => _buildTotalsRow(context, summary),
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(),
                  ),
              error:
                  (_, __) =>
                      _buildTotalsRow(context, const WalletSummary(0, 0, 0)),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.all(Radius.circular(33)),
            ),
            child: const DatePickerCalendar(),
          ),
        ),
        const Expanded(child: BonusInfoList()),
      ],
    );
  }
}

class _WalletStatsTool extends ConsumerStatefulWidget {
  const _WalletStatsTool();

  @override
  ConsumerState<_WalletStatsTool> createState() => _WalletStatsToolState();
}

class _WalletStatsToolState extends ConsumerState<_WalletStatsTool> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';
  _StatsChartMode _chartMode = _StatsChartMode.daily;
  String? _selectedProductKey;

  static const double _dailyChartMaxBonus = 45;
  static const double _monthlyChartMaxBonus = 900;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bonusInfo = ref.watch(bonusInfoListProvider).bonusInfo;
    final products = ref.watch(productInfoProvider);
    final productivity = _buildProductProductivity(bonusInfo, products);
    if (_selectedProductKey != null &&
        !productivity.any((stat) => stat.key == _selectedProductKey)) {
      _selectedProductKey = null;
    }
    final filtered =
        _filter.isEmpty
            ? productivity.take(3).toList()
            : productivity
                .where(
                  (stat) => stat.displayName.toLowerCase().contains(
                    _filter.toLowerCase(),
                  ),
                )
                .toList();
    _ProductProductivity? selectedProduct;
    for (final stat in productivity) {
      if (stat.key == _selectedProductKey) {
        selectedProduct = stat;
        break;
      }
    }
    final chartEntries = _buildChartEntries(
      bonusInfo: bonusInfo,
      mode: _chartMode,
      selectedProductKey: _selectedProductKey,
    );
    final includeYearInDailyLabels = _chartSpansMultipleYears(chartEntries);
    final chartMaxBonus =
        _chartMode == _StatsChartMode.monthly
            ? _monthlyChartMaxBonus
            : _dailyChartMaxBonus;
    final totalBonus = chartEntries.fold<double>(0, (sum, d) => sum + d.value);
    final avgBonus =
        chartEntries.isEmpty ? 0.0 : totalBonus / chartEntries.length;
    final totalKg = productivity.fold<double>(
      0,
      (sum, stat) => sum + stat.totalKg,
    );
    final topWeightProduct =
        productivity.isEmpty
            ? null
            : productivity.reduce((a, b) => a.totalKg >= b.totalKg ? a : b);
    final maxEntry =
        chartEntries.isEmpty
            ? null
            : chartEntries.reduce((a, b) => a.value >= b.value ? a : b);
    final chartTitle = switch (_chartMode) {
      _StatsChartMode.daily => 'Daily bonus',
      _StatsChartMode.product =>
        selectedProduct == null
            ? 'Product bonus'
            : '${selectedProduct.displayName} bonus',
      _StatsChartMode.monthly => 'Monthly bonus',
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stats', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                SegmentedButton<_StatsChartMode>(
                  segments: const [
                    ButtonSegment(
                      value: _StatsChartMode.daily,
                      label: Text('Day'),
                    ),
                    ButtonSegment(
                      value: _StatsChartMode.product,
                      label: Text('Product'),
                    ),
                    ButtonSegment(
                      value: _StatsChartMode.monthly,
                      label: Text('Month'),
                    ),
                  ],
                  selected: {_chartMode},
                  onSelectionChanged: (selection) {
                    setState(() => _chartMode = selection.first);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '$chartTitle chart (0-${chartMaxBonus.toStringAsFixed(0)})',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      label: 'Average',
                      value: '£${formatDouble(avgBonus)}',
                    ),
                    _StatChip(
                      label: 'Moved',
                      value: '${formatDouble(totalKg)} kg',
                    ),
                    _StatChip(
                      label: 'Top kg',
                      value:
                          topWeightProduct == null
                              ? 'n/a'
                              : '${topWeightProduct.displayName} (${formatDouble(topWeightProduct.totalKg)} kg)',
                    ),
                    _StatChip(
                      label: 'Best',
                      value:
                          maxEntry == null
                              ? 'n/a'
                              : '${maxEntry.displayLabel(includeYearInDailyLabels: includeYearInDailyLabels)} (£${formatDouble(maxEntry.value)})',
                    ),
                    _StatChip(
                      label: switch (_chartMode) {
                        _StatsChartMode.daily => 'Days',
                        _StatsChartMode.product => 'Days',
                        _StatsChartMode.monthly => 'Months',
                      },
                      value: '${chartEntries.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.78,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child:
                      chartEntries.isEmpty
                          ? Center(
                            child: Text(
                              _chartMode == _StatsChartMode.product
                                  ? 'Select a product to show its bonus chart.'
                                  : 'No bonus history yet.',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                          : _BonusChart(
                            entries: chartEntries,
                            maxValue: chartMaxBonus,
                            includeYearInDailyLabels: includeYearInDailyLabels,
                          ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Per-product productivity',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _filterController,
                  onChanged: (value) => setState(() => _filter = value.trim()),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface.withValues(
                      alpha: 0.95,
                    ),
                    hintText: 'Filter by product name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _filter.isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _filterController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (productivity.isEmpty)
                  Text(
                    'No product history yet.',
                    style: theme.textTheme.bodySmall,
                  )
                else if (filtered.isEmpty)
                  Text(
                    'No products match that filter.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final rawWidth = (constraints.maxWidth - 8) / 2;
                      final tileWidth = rawWidth.clamp(150.0, 240.0);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            filtered
                                .map(
                                  (stat) => SizedBox(
                                    width: tileWidth,
                                    child: _ProductProductivityTile(
                                      stat: stat,
                                      selected: stat.key == _selectedProductKey,
                                      onTap: () {
                                        setState(() {
                                          _selectedProductKey = stat.key;
                                          _chartMode = _StatsChartMode.product;
                                        });
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Text(
                  chartEntries.any((entry) => entry.value > chartMaxBonus)
                      ? 'Some ${_chartMode == _StatsChartMode.monthly ? 'months' : 'days'} exceed £${chartMaxBonus.toStringAsFixed(0)}; points are capped.'
                      : _chartMode == _StatsChartMode.monthly
                      ? 'Dots reflect monthly bonus totals.'
                      : 'Dots reflect daily bonus totals.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _StatsChartMode { daily, product, monthly }

List<_ChartEntry> _buildChartEntries({
  required List<BonusInfo> bonusInfo,
  required _StatsChartMode mode,
  required String? selectedProductKey,
}) {
  final grouped = <DateTime, double>{};
  for (final info in bonusInfo) {
    if (mode == _StatsChartMode.product) {
      if (selectedProductKey == null) continue;
      final hasSelectedProduct = info.produced.any(
        (produced) =>
            produced.productName.toLowerCase().trim() == selectedProductKey,
      );
      if (!hasSelectedProduct) continue;
    }

    final key =
        mode == _StatsChartMode.monthly
            ? _payPeriodEndMonth(info.date)
            : DateTime(info.date.year, info.date.month, info.date.day);
    grouped[key] = (grouped[key] ?? 0.0) + info.bonus;
  }

  final sortedKeys = grouped.keys.toList()..sort();
  return sortedKeys
      .map(
        (key) => _ChartEntry(
          label:
              mode == _StatsChartMode.monthly
                  ? _shortMonthLabelFromDate(key)
                  : _shortDayLabel(key, includeYear: false),
          date: key,
          value: grouped[key] ?? 0.0,
        ),
      )
      .toList();
}

DateTime _payPeriodEndMonth(DateTime date) {
  final end =
      date.day >= 19
          ? DateTime(date.year, date.month + 1, 18)
          : DateTime(date.year, date.month, 18);
  return DateTime(end.year, end.month);
}

bool _chartSpansMultipleYears(List<_ChartEntry> entries) {
  if (entries.length < 2) return false;
  final firstYear = entries.first.date.year;
  return entries.any((entry) => entry.date.year != firstYear);
}

String _shortDayLabel(DateTime date, {required bool includeYear}) {
  final dayMonth = '${date.day}/${date.month}';
  if (!includeYear) return dayMonth;
  final yearShort = (date.year % 100).toString().padLeft(2, '0');
  return '$dayMonth/$yearShort';
}

String _shortMonthLabelFromDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final yearShort = (date.year % 100).toString().padLeft(2, '0');
  return '${months[date.month - 1]} $yearShort';
}

List<_ProductProductivity> _buildProductProductivity(
  List<BonusInfo> bonusInfo,
  List<ProductInfo> products,
) {
  final targetByKey = <String, int>{};
  final displayByKey = <String, String>{};
  final gramsByKey = <String, double>{};
  for (final item in products) {
    final key = item.productName.toLowerCase().trim();
    if (key.isEmpty) continue;
    targetByKey[key] = item.target;
    displayByKey[key] = item.productName;
    gramsByKey[key] = item.finalProductWeightGrams;
  }

  final stats = <String, _ProductProductivity>{};
  for (final info in bonusInfo) {
    for (final produced in info.produced) {
      final key = produced.productName.toLowerCase().trim();
      if (key.isEmpty) continue;
      final displayName = displayByKey[key] ?? produced.productName.trim();
      stats
          .putIfAbsent(
            key,
            () => _ProductProductivity(
              key: key,
              displayName: displayName,
              target: targetByKey[key],
              gramsPerUnit: gramsByKey[key] ?? 0,
            ),
          )
          .addAmount(produced.amount);
    }
  }

  final list =
      stats.values.toList()
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
  return list;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110, maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.82,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductProductivity {
  _ProductProductivity({
    required this.key,
    required this.displayName,
    required this.target,
    required this.gramsPerUnit,
  });

  final String key;
  final String displayName;
  final int? target;
  final double gramsPerUnit;
  int totalAmount = 0;
  int entries = 0;

  void addAmount(int amount) {
    totalAmount += amount;
    entries += 1;
  }

  double get avgPerEntry => entries == 0 ? 0.0 : totalAmount / entries;

  double get totalKg => totalAmount * gramsPerUnit / 1000;

  int? get targetPercent {
    if (target == null || target == 0) return null;
    return ((avgPerEntry / target!) * 100).round();
  }
}

class _ProductProductivityTile extends StatelessWidget {
  const _ProductProductivityTile({
    required this.stat,
    required this.selected,
    required this.onTap,
  });

  final _ProductProductivity stat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primaryContainer.withValues(
      alpha: 0.82,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              selected
                  ? selectedColor
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.72,
                  ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected
                    ? theme.colorScheme.primary
                    : theme.dividerColor.withValues(alpha: 0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ${formatDouble(stat.totalAmount.toDouble(), fractionDigits: 0)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Moved: ${formatDouble(stat.totalKg)} kg',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Avg/entry: ${formatDouble(stat.avgPerEntry, fractionDigits: 0)}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              stat.target == null || stat.target == 0
                  ? 'Target: n/a'
                  : 'Target: ${stat.target} (${stat.targetPercent}%)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusChart extends StatefulWidget {
  const _BonusChart({
    required this.entries,
    required this.maxValue,
    required this.includeYearInDailyLabels,
  });

  final List<_ChartEntry> entries;
  final double maxValue;
  final bool includeYearInDailyLabels;

  @override
  State<_BonusChart> createState() => _BonusChartState();
}

class _BonusChartState extends State<_BonusChart> {
  final ScrollController _scrollController = ScrollController();
  int _positionedEntryCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
  }

  @override
  void didUpdateWidget(covariant _BonusChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _positionedEntryCount = -1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToLatest());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToLatest() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_positionedEntryCount == widget.entries.length) return;
    _positionedEntryCount = widget.entries.length;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    const axisWidth = 32.0;
    const axisGap = 8.0;
    const labelHeight = 26.0;
    const pointSpacing = 56.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - axisWidth - axisGap;
        final naturalWidth =
            widget.entries.isEmpty
                ? pointSpacing
                : widget.entries.length * pointSpacing;
        final chartWidth =
            availableWidth < 0
                ? naturalWidth
                : (naturalWidth > availableWidth
                    ? naturalWidth
                    : availableWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: axisWidth,
              child: Column(
                children: [
                  _AxisLabel(widget.maxValue.toStringAsFixed(0)),
                  const Spacer(),
                  _AxisLabel((widget.maxValue * 2 / 3).toStringAsFixed(0)),
                  const Spacer(),
                  _AxisLabel((widget.maxValue / 3).toStringAsFixed(0)),
                  const Spacer(),
                  const _AxisLabel('0'),
                ],
              ),
            ),
            const SizedBox(width: axisGap),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: _BonusLineChart(
                    entries: widget.entries,
                    maxValue: widget.maxValue,
                    labelHeight: labelHeight,
                    includeYearInDailyLabels: widget.includeYearInDailyLabels,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BonusLineChart extends StatelessWidget {
  const _BonusLineChart({
    required this.entries,
    required this.maxValue,
    required this.labelHeight,
    required this.includeYearInDailyLabels,
  });

  final List<_ChartEntry> entries;
  final double maxValue;
  final double labelHeight;
  final bool includeYearInDailyLabels;

  @override
  Widget build(BuildContext context) {
    return _InteractiveBonusLineChart(
      entries: entries,
      maxValue: maxValue,
      labelHeight: labelHeight,
      includeYearInDailyLabels: includeYearInDailyLabels,
    );
  }
}

class _InteractiveBonusLineChart extends StatefulWidget {
  const _InteractiveBonusLineChart({
    required this.entries,
    required this.maxValue,
    required this.labelHeight,
    required this.includeYearInDailyLabels,
  });

  final List<_ChartEntry> entries;
  final double maxValue;
  final double labelHeight;
  final bool includeYearInDailyLabels;

  @override
  State<_InteractiveBonusLineChart> createState() =>
      _InteractiveBonusLineChartState();
}

class _InteractiveBonusLineChartState
    extends State<_InteractiveBonusLineChart> {
  int? _selectedIndex;

  void _handleTap(Offset localPosition, Size size) {
    if (widget.entries.isEmpty) return;
    final step = size.width / widget.entries.length;
    final index =
        (localPosition.dx / step).clamp(0, widget.entries.length - 1).floor();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = (constraints.maxHeight - widget.labelHeight).clamp(
          0.0,
          constraints.maxHeight,
        );
        final labelStep =
            widget.entries.isEmpty
                ? constraints.maxWidth
                : constraints.maxWidth / widget.entries.length;
        return Column(
          children: [
            SizedBox(
              height: chartHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown:
                    (details) => _handleTap(
                      details.localPosition,
                      Size(constraints.maxWidth, chartHeight),
                    ),
                child: CustomPaint(
                  painter: _LineChartPainter(
                    entries: widget.entries,
                    maxValue: widget.maxValue,
                    lineColor: Colors.green[500] ?? Colors.green,
                    dotColor: Colors.green[700] ?? Colors.green,
                    gridColor: theme.dividerColor,
                    selectedIndex: _selectedIndex,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            SizedBox(
              height: widget.labelHeight,
              child: Row(
                children:
                    widget.entries.map((entry) {
                      return SizedBox(
                        width: labelStep,
                        child: Text(
                          entry.displayLabel(
                            includeYearInDailyLabels:
                                widget.includeYearInDailyLabels,
                          ),
                          style: theme.textTheme.labelSmall,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.entries,
    required this.maxValue,
    required this.lineColor,
    required this.dotColor,
    required this.gridColor,
    required this.selectedIndex,
  });

  final List<_ChartEntry> entries;
  final double maxValue;
  final Color lineColor;
  final Color dotColor;
  final Color gridColor;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 10.0;
    const bottomPadding = 4.0;
    final usableHeight = (size.height - topPadding - bottomPadding).clamp(
      0.0,
      size.height,
    );
    final gridPaint =
        Paint()
          ..color = gridColor.withValues(alpha: 0.2)
          ..strokeWidth = 1;
    final yPositions = <double>[
      topPadding,
      topPadding + usableHeight * 0.333,
      topPadding + usableHeight * 0.666,
      topPadding + usableHeight,
    ];
    for (final y in yPositions) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (entries.isEmpty) return;

    final linePaint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
    final dotPaint =
        Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;

    final step = entries.length <= 1 ? size.width : size.width / entries.length;
    final points = <Offset>[];
    for (var i = 0; i < entries.length; i++) {
      final clamped = (entries[i].value / maxValue).clamp(0.0, 1.0);
      final x = entries.length <= 1 ? size.width / 2 : (i + 0.5) * step;
      final y = topPadding + (1 - clamped) * usableHeight;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    final dotBorderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    for (final point in points) {
      canvas
        ..drawCircle(point, 4, dotPaint)
        ..drawCircle(point, 4, dotBorderPaint);
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < points.length) {
      final point = points[selectedIndex!];
      final entry = entries[selectedIndex!];
      final label =
          '${entry.displayLabel(includeYearInDailyLabels: true)}\n£${formatDouble(entry.value)}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout();
      const padding = 6.0;
      final bubbleWidth = textPainter.width + padding * 2;
      final bubbleHeight = textPainter.height + padding * 1.5;
      var bubbleX = point.dx - bubbleWidth / 2;
      bubbleX = bubbleX.clamp(0.0, size.width - bubbleWidth);
      final bubbleY = (point.dy - bubbleHeight - 10).clamp(
        0.0,
        size.height - bubbleHeight,
      );
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleX, bubbleY, bubbleWidth, bubbleHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        bubbleRect,
        Paint()..color = dotColor.withValues(alpha: 0.9),
      );
      textPainter.paint(
        canvas,
        Offset(
          bubbleX + padding,
          bubbleY + (bubbleHeight - textPainter.height) / 2,
        ),
      );
      canvas.drawCircle(point, 6, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall,
      textAlign: TextAlign.right,
    );
  }
}

class _ChartEntry {
  const _ChartEntry({
    required this.label,
    required this.date,
    required this.value,
  });

  final String label;
  final DateTime date;
  final double value;

  String displayLabel({required bool includeYearInDailyLabels}) {
    if (label.contains(' ')) return label;
    return _shortDayLabel(date, includeYear: includeYearInDailyLabels);
  }
}
