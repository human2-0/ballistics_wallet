import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DatePickerCalendar extends ConsumerStatefulWidget {
  const DatePickerCalendar({super.key});

  @override
  DatePickerCalendarState createState() => DatePickerCalendarState();
}

class DatePickerCalendarState extends ConsumerState {
  late DateTime _currentViewDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(bonusInfoListProvider.notifier)
          .loadBonusInfos()
          .catchError(debugPrint);
    });
    _currentViewDate = DateTime
        .now(); // Initialize with the current date or another appropriate date
  }

  Key _calendarKey = UniqueKey();

  void moveToLastMonth() {
    setState(() {
      _currentViewDate = DateTime(
        _currentViewDate.year,
        _currentViewDate.month - 1,
        _currentViewDate.day,
      );
      // Force the calendar to rebuild with the new date
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
                  .where(
                    (info) => isSameDay(info.date, date),
                  )
                  .toList();

              // Original color scheme for non-selected cells
              const primaryColor = Colors.orange;

              // Define a slightly different color scheme for selected cells
              const selectedPrimaryColor =
                  Colors.blue; // Change this color as needed

              // Determine the decoration based on whether the cell is selected
              final cellDecoration = isSelected ?? false
                  ? BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.1, 0.5, 0.7, 0.9],
                        colors: [
                          selectedPrimaryColor[50]!.withOpacity(0.5),
                          selectedPrimaryColor[100]!,
                          selectedPrimaryColor[200]!,
                          selectedPrimaryColor[300]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedPrimaryColor[500]!.withOpacity(0.6),
                          offset: const Offset(5, 5),
                          blurRadius: 5,
                          spreadRadius: -5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
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
                          primaryColor[50]!.withOpacity(0.5),
                          primaryColor[100]!,
                          primaryColor[200]!,
                          primaryColor[300]!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor[500]!.withOpacity(0.6),
                          offset: const Offset(5, 5),
                          blurRadius: 5,
                          spreadRadius: -5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          offset: const Offset(-5, -5),
                          blurRadius: 5,
                          spreadRadius: -2,
                        ),
                      ],
                    );

              // Adjust textStyle for selected cells if necessary, else use default textStyle

              return DecoratedBox(
                decoration: cellDecoration,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        date.day.toString(),
                        style: const TextStyle(
                          color: Colors.black, // Adjust color based on selection
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...dailyBonusInfo.map(
                      (info) => Text(
                        '£${info.bonus.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          value: [selectedDate],
          onValueChanged: (values) {
            if (values.isNotEmpty) {
              ref.read(selectedDateProvider.notifier).state = values.first!;
            }
          },
        ),
      ],
    );
  }

  bool isSameDay(DateTime? date1, DateTime? date2) => date1?.year == date2?.year &&
        date1?.month == date2?.month &&
        date1?.day == date2?.day;
}
