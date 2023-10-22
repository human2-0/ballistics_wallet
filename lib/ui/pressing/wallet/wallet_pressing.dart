import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../providers/pressing_db_provider.dart';
import '../../../providers/wallet_provider.dart';
import 'bonus_history_drawer.dart';
import 'bonus_list_view.dart';
import 'monthly_bonus.dart';
import 'total_monthly_working_hours.dart';

class BonusCalendar extends HookConsumerWidget {
  final String userId;
  final Function(ScrollNotification) onNotification; // Add ScrollController

  const BonusCalendar(
      {super.key, required this.userId, required this.onNotification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _calendarFormat = useState(CalendarFormat.month);
    final _focusedDay = useState(DateTime.now());
    final _selectedDay = useState<DateTime?>(null);
    final _selectedEvents = useState<List<dynamic>>([]);

    final userBonuses = ref.watch(userBonusNotifierProvider);

    Future<void> _fetchUserBonuses(WidgetRef ref) async {
      final pressingRepository = ref.read(pressingRepositoryProvider);
      final userBonusesNotifier = ref.read(userBonusNotifierProvider.notifier);

      Map<DateTime, List<dynamic>> userBonuses =
          await pressingRepository.fetchUserBonuses(userId);

      // To debug and see if data is fetched

      userBonusesNotifier.setUserBonuses(userBonuses);
    }

    // Re-fetch bonuses when userId changes
    useEffect(() {
      _fetchUserBonuses(ref);
      if (_selectedDay.value != null) {
        DateTime localDay = DateTime(_selectedDay.value!.year,
                _selectedDay.value!.month, _selectedDay.value!.day)
            .toLocal();
        _selectedEvents.value = userBonuses[localDay] ?? [];
      }
      return null;
    }, [userBonuses]);

    void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
      DateTime localDay =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day)
              .toLocal();
      _selectedDay.value = selectedDay;
      _focusedDay.value = focusedDay;
      _selectedEvents.value = userBonuses[localDay] ?? [];
    }

    void onDeleteBonus(int parentIndex, int childIndex) {
      // Get the ID of the parent bonus
      final parentId = _selectedEvents.value[parentIndex]['id'];

      // Check if the 'produced' list is not empty
      if (_selectedEvents.value[parentIndex]['produced'].isNotEmpty) {
        // Get the child bonus item that we want to delete
        final childBonus =
            _selectedEvents.value[parentIndex]['produced'][childIndex];

        // Get the ID of the child bonus
        final childId = childBonus['id'];

        // Perform the delete operation in the background
        ref
            .read(userBonusNotifierProvider.notifier)
            .deleteIndividualBonus(userId, parentId, childId);

        // Remove the child bonus from the parent's produced list immediately
        _selectedEvents.value[parentIndex]['produced'].removeAt(childIndex);

        // If there are no more child bonuses in the parent's produced list,
        // also remove the parent from the _selectedEvents list
        if (_selectedEvents.value[parentIndex]['produced'].isEmpty) {
          _selectedEvents.value.removeAt(parentIndex);
        }
      }
    }

    List<dynamic> eventLoader(DateTime day) {
      DateTime localDay = DateTime(day.year, day.month, day.day).toLocal();
      List<dynamic> eventsForDay = userBonuses[localDay] ?? [];

      // If there are no events, return an empty list
      if (eventsForDay.isEmpty) {
        return [];
      }

      // If there are events, sum their bonuses and return a single event with the total bonus
      double totalBonus = eventsForDay.fold(0.0, (sum, currentEvent) {
        return sum + (currentEvent['bonus'] as double);
      });

      // Return a list containing a single map with the total bonus
      return [
        {
          'bonus': totalBonus,
        },
      ];
    }

    void onAddBonus(Map<String, dynamic> newBonus) {
      try {
        if (newBonus['productName'] != null &&
            newBonus['bonus'] != null &&
            newBonus['amount'] != null) {
          String userId = ref.watch(authRepositoryProvider).currentUserId;
          double? workingHours = ref
              .read(userNotifierProvider)
              .realWorkingHours; // Replace with actual user id
          String productName = newBonus['productName'];
          double bonus = newBonus['bonus'];
          int amount = newBonus['amount'];
          DateTime selectedEventDate = newBonus[
              'selectedDate']; // Replace with actual selected event date

          ref
              .read(userBonusNotifierProvider.notifier)
              .saveUserBonusCalendar(userId, productName, bonus, amount,
                  selectedEventDate, workingHours!)
              .then((_) {
            // Update selectedEvents using the new provider
            //ref.read(selectedEventsProvider.notifier).addBonus(newBonus);
            //var previousDay = _selectedDay.value;
            //_selectedDay.value = null;
            //_selectedDay.value = previousDay;
          }).catchError((error) {});
        } else {}
      } catch (e) {}
    }


    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          onNotification(notification);
          return true;
        },
        child: Stack(children: [
          Image.asset(
            'assets/wallet_screen.jpg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Column(
            children: [
              Stack(
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MonthlyWorkingHours(),
                        MonthlyBonus(),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Builder(
                      builder: (context) => IconButton(
                        iconSize: 30,
                        icon: const Icon(Icons.history_outlined),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(33)),
                    color: Colors.grey[100],
                  ),
                  child: TableCalendar(
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarBuilders: CalendarBuilders(
                      singleMarkerBuilder: (context, date, event) {
                        if (event is Map<String, dynamic> &&
                            event.containsKey('bonus')) {
                          final double bonus = event['bonus'] as double;
                          return bonus > 0
                              ? Container(
                                  color: Colors.green[50]!.withOpacity(0.5),
                                  child: Text(
                                    '£${formatDouble(bonus)}',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Container();
                        } else {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    ),
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay.value,
                    calendarFormat: _calendarFormat.value,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay.value, day),
                    onDaySelected: onDaySelected,
                    eventLoader: eventLoader,
                    onFormatChanged: (format) => _calendarFormat.value = format,
                    onPageChanged: (focusedDay) =>
                        _focusedDay.value = focusedDay,
                    calendarStyle: const CalendarStyle(
                      isTodayHighlighted: true,
                      cellMargin: EdgeInsets.all(13),
                      markerDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              if (_selectedDay.value != null)
                Expanded(
                  child: BonusListView(
                    selectedEvents:
                        _selectedEvents.value.cast<Map<String, dynamic>>(),
                    selectedDate: _selectedDay.value!,
                    userId: userId,
                    onDelete: onDeleteBonus,
                    onAdd: onAddBonus,
                  ),
                ),
            ],
          ),
        ]),
      ),
      endDrawer: BonusHistoryDrawer(onNotification: onNotification),
    );
  }
}
