import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/models/custom_date_range.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatePickerCalendar extends ConsumerStatefulWidget {
  const DatePickerCalendar({super.key});

  @override
  DatePickerCalendarState createState() => DatePickerCalendarState();
}

class DatePickerCalendarState extends ConsumerState<DatePickerCalendar> {
  late DateTime _currentViewDate;
  Key _calendarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
                .read(bonusInfoListProvider.notifier)
                .loadBonusInfos()
                .catchError((Object e, StackTrace st) {
                  debugPrint('loadBonusInfos failed → $e');
               });
    });
    _currentViewDate = DateTime.now();
  }

  void moveToLastMonth() {
    setState(() {
      _currentViewDate = DateTime(
        _currentViewDate.year,
        _currentViewDate.month - 1,
        _currentViewDate.day,
      );
      _calendarKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bonusInfoList = ref.watch(bonusInfoListProvider).bonusInfo;
    final selectedDate = ref.watch(selectedDateProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async => _handlePickCustomRange(context, bonusInfoList),
          child: const Text('Pick custom range'),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendSwatch(color: Colors.purple, label: 'Hours range'),
            SizedBox(width: 12),
            _LegendSwatch(color: Colors.green, label: 'Bonus range'),
          ],
        ),
        const SizedBox(height: 8),
        CalendarDatePicker2(
          key: _calendarKey,
          config: CalendarDatePicker2Config(
            firstDayOfWeek: 1,
            centerAlignModePicker: true,
            disableModePicker: true,
            calendarType: CalendarDatePicker2Type.single,
            dayBuilder: ({
              required date,
              decoration,
              isDisabled,
              isSelected,
              isToday,
              textStyle,
            }) {
              final dailyBonusInfo = bonusInfoList
                  .where((info) => isSameDay(info.date, date))
                  .toList();

              // Determine if this day is within custom ranges (hours / bonus)
              CustomDateRange? savedRange;
              if (Hive.isBoxOpen('customDateRangeBox')) {
                final box = Hive.box<CustomDateRange>('customDateRangeBox');
                savedRange = box.get('myCustomDateRange');
              }

              var inHours = false;
              var inBonus = false;
              if (savedRange != null) {
                final d = _dateOnly(date);
                if (savedRange.hoursStart != null && savedRange.hoursEnd != null) {
                  final hs = _dateOnly(savedRange.hoursStart!);
                  final he = _dateOnly(savedRange.hoursEnd!);
                  inHours = !d.isBefore(hs) && !d.isAfter(he);
                }
                if (savedRange.bonusStart != null && savedRange.bonusEnd != null) {
                  final bs = _dateOnly(savedRange.bonusStart!);
                  final be = _dateOnly(savedRange.bonusEnd!);
                  inBonus = !d.isBefore(bs) && !d.isAfter(be);
                }
              }

              // Non-selected cell color
              const primaryColor = Colors.orange;
              // Selected cell color
              const selectedPrimaryColor = Colors.blue;

              final cellDecoration = (isSelected ?? false)
                  ? BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.1, 0.5, 0.7, 0.9],
                        colors: [
                          selectedPrimaryColor[50]!.withValues(alpha: 0.4),
                          selectedPrimaryColor[100]!,
                          selectedPrimaryColor[200]!,
                          selectedPrimaryColor[300]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedPrimaryColor[500]!.withValues(alpha: 0.6),
                          offset: const Offset(5, 5),
                          blurRadius: 5,
                          spreadRadius: -5,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          offset: const Offset(-5, -5),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    )
                  : BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.1, 0.5, 0.7, 0.9],
                        colors: [
                          primaryColor[50]!.withValues(alpha: 0.5),
                          primaryColor[100]!,
                          primaryColor[200]!,
                          primaryColor[300]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor[500]!.withValues(alpha: 0.6),
                          offset: const Offset(5, 5),
                          blurRadius: 5,
                          spreadRadius: -5,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          offset: const Offset(-5, -5),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    );

              // Build the base day cell
              final baseCell = DecoratedBox(
                decoration: cellDecoration,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        date.day.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...dailyBonusInfo.map(
                      (info) => Text(
                        '£${formatDouble(info.bonus)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              );

              // Overlay visual highlights for custom ranges
              return Stack(
                fit: StackFit.expand,
                children: [
                  baseCell,
                  if (inHours)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.purple[50]!.withValues(alpha: 0.18),
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                            border: Border.all(
                              color: Colors.purple[200]!.withValues(alpha: 0.9),
                              width: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (inBonus)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          margin: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: Colors.green[50]!.withValues(alpha: 0.14),
                            borderRadius: const BorderRadius.all(Radius.circular(13)),
                            border: Border.all(
                              color: Colors.green[300]!.withValues(alpha: 0.9),
                              width: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          value: [selectedDate],
          onValueChanged: (values) {
            if (values.isNotEmpty) {
              ref.read(selectedDateProvider.notifier).state = values.first;
            }
          },
        ),
      ],
    );
  }

  /// No `BuildContext` usage after an `await` -> store context in local variable
  Future<void> _handlePickCustomRange(
    BuildContext context,
    List<BonusInfo> bonusInfoList,
  ) async {
    final localContext = context;

    // Step 1: pick range for total hours
    final hoursRange = await _pickRange(localContext, 'Select Range for Hours');
    // If user pressed cancel => hoursRange == null => exit
    if (hoursRange == null || hoursRange.length != 2) {
      return;
    }

    if (!context.mounted) return;

    // Step 2: pick range for total bonuses
    final bonusRange =
        await _pickRange(localContext, 'Select Range for Bonuses');
    // If user pressed cancel => bonusRange == null => exit
    if (bonusRange == null || bonusRange.length != 2) {
      return;
    }

    // Save these custom ranges to Hive
    final customRangeBox =
        await Hive.openBox<CustomDateRange>('customDateRangeBox');
    final customDateRange = CustomDateRange(
      hoursStart: hoursRange[0],
      hoursEnd: hoursRange[1],
      bonusStart: bonusRange[0],
      bonusEnd: bonusRange[1],
    );
    await customRangeBox.put('myCustomDateRange', customDateRange);

    // **Force the provider to refresh and recalc** so UI sees updated range
    await ref.read(bonusInfoListProvider.notifier).loadBonusInfos();

    // Optionally, if needed, re-build DatePickerCalendar itself:
    setState(() {});

    // Now calculate the custom totals (hours, bonus, total salary)
    final results = _calculateCustomRangeTotals(
      ref,
      bonusInfoList,
      hoursRange[0],
      hoursRange[1],
      bonusRange[0],
      bonusRange[1],
    );

    // If the widget was removed from the tree while we waited, bail out
    if (!context.mounted) return;

    // Show the results in a dialog
    await showDialog<void>(
      context: localContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Range Results'),
        content: SingleChildScrollView(
          child: Text(
            'Hours Range: ${_formatDate(hoursRange[0])} - ${_formatDate(hoursRange[1])}\n'
            'Bonus Range: ${_formatDate(bonusRange[0])} - ${_formatDate(bonusRange[1])}\n\n'
            'Total Hours: ${formatDouble(results['hours']!)}\n'
            'Total Bonus: £${formatDouble(results['bonus']!)}\n'
            'Total Salary: £${formatDouble(results['salary']!)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(localContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<List<DateTime?>?> _pickRange(
    BuildContext context,
    String title,
  ) async {
    // Capture the BuildContext in a local variable *before* any await
    final localContext = context;

    // 1) Open your Hive box (async gap below)
    final customRangeBox =
        await Hive.openBox<CustomDateRange>('customDateRangeBox');
    // (If you're in a State or ConsumerState, optionally you can do `if (!mounted) return null;`)
    if (!localContext.mounted) return null;

    final savedRange = customRangeBox.get('myCustomDateRange');

    // 2) Decide which set of dates to show initially
    final initialDates = <DateTime?>[];
    if (savedRange != null) {
      if (title.toLowerCase().contains('hours')) {
        initialDates
          ..add(savedRange.hoursStart)
          ..add(savedRange.hoursEnd);
      } else if (title.toLowerCase().contains('bonus')) {
        initialDates
          ..add(savedRange.bonusStart)
          ..add(savedRange.bonusEnd);
      }
    } else {
      initialDates.addAll([null, null]);
    }

    final config = CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.range,
      centerAlignModePicker: true,
      firstDayOfWeek: 1,
    );

    final backgroundColor = title.toLowerCase().contains('hours')
        ? Colors.purple[50]
        : title.toLowerCase().contains('bonus')
            ? Colors.green[50]
            : Colors.white;

    // 3) Invoke showDialog **synchronously**, using your localContext
    return showDialog<List<DateTime?>?>(
      context: localContext,
      builder: (dialogContext) => Dialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(localContext).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 400,
              width: 325,
              child: CalendarDatePicker2WithActionButtons(
                config: config,
                value: initialDates,
                onCancelTapped: () => Navigator.of(dialogContext).pop(),
                onValueChanged: (values) {
                  Navigator.of(dialogContext).pop(values);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Calculate custom totals for hours & bonus in different ranges
  Map<String, double> _calculateCustomRangeTotals(
    WidgetRef ref,
    List<BonusInfo> bonusInfoList,
    DateTime? hoursStart,
    DateTime? hoursEnd,
    DateTime? bonusStart,
    DateTime? bonusEnd,
  ) {
    if (hoursStart == null ||
        hoursEnd == null ||
        bonusStart == null ||
        bonusEnd == null) {
      return {'hours': 0, 'bonus': 0, 'salary': 0};
    }

    final userState = ref.watch(userNotifierProvider);
    final hourlyRate = userState.hourlyRate ?? 0;

    var totalHours = 0.0;
    for (final info in bonusInfoList) {
      final date = info.date;
      if (date.isAfterOrSame(hoursStart) && date.isBeforeOrSame(hoursEnd)) {
        totalHours += info.workingHours;
      }
    }

    var totalBonus = 0.0;
    for (final info in bonusInfoList) {
      final date = info.date;
      if (date.isAfterOrSame(bonusStart) && date.isBeforeOrSame(bonusEnd)) {
        totalBonus += info.bonus;
      }
    }

    final totalSalary = totalBonus + (totalHours * hourlyRate);

    return {
      'hours': totalHours,
      'bonus': totalBonus,
      'salary': totalSalary,
    };
  }

  bool isSameDay(DateTime? date1, DateTime? date2) =>
      date1?.year == date2?.year &&
      date1?.month == date2?.month &&
      date1?.day == date2?.day;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.65), width: 1.25),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

extension DateCompare on DateTime {
  bool isAfterOrSame(DateTime other) {
    final current = _dateOnly(this);
    final target = _dateOnly(other);
    return current.isAfter(target) || current.isAtSameMomentAs(target);
  }

  bool isBeforeOrSame(DateTime other) {
    final current = _dateOnly(this);
    final target = _dateOnly(other);
    return current.isBefore(target) || current.isAtSameMomentAs(target);
  }
}
