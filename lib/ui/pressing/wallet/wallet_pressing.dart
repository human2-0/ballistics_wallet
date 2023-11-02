import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_history_drawer.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/bonus_list_view.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/monthly_bonus.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/wallet/total_monthly_working_hours.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

class BonusCalendar extends HookConsumerWidget { // Add ScrollController

  const BonusCalendar(
      {required this.userId, required this.onNotification, super.key});
  final String userId;
  final void Function(ScrollNotification) onNotification;

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

      final userBonuses =
          await pressingRepository.fetchUserBonuses(userId);

      // To debug and see if data is fetched

      userBonusesNotifier.setUserBonuses(userBonuses);
    }

    // Re-fetch bonuses when userId changes
    useEffect(() {
      _fetchUserBonuses(ref);
      if (_selectedDay.value != null) {
        final localDay = DateTime(_selectedDay.value!.year,
                _selectedDay.value!.month, _selectedDay.value!.day)
            .toLocal();
        _selectedEvents.value = userBonuses[localDay] ?? [];
      }
      return null;
    }, [userBonuses]);

    void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
      final localDay =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day)
              .toLocal();
      _selectedDay.value = selectedDay;
      _focusedDay.value = focusedDay;
      _selectedEvents.value = userBonuses[localDay] ?? [];
    }

    Future<void> onDeleteBonus(int parentIndex, int childIndex) async {
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
        await ref
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
      final localDay = DateTime(day.year, day.month, day.day).toLocal();
      final eventsForDay = userBonuses[localDay] ?? [];

      // If there are no events, return an empty list
      if (eventsForDay.isEmpty) {
        return [];
      }

      // If there are events, sum their bonuses and return a single event with the total bonus
      final totalBonus = eventsForDay.fold(0.0, (sum, currentEvent) => sum + (currentEvent['bonus'] as double));



      // Return a list containing a single map with the total bonus
      return [
        {
          'bonus': totalBonus,
        },
      ];
    }

    Future<void> onAddBonus(Map<String, dynamic> newBonus) async {
      try {
        if (newBonus['productName'] != null &&
            newBonus['bonus'] != null &&
            newBonus['amount'] != null) {
          final userId = ref.watch(authRepositoryProvider).currentUserId;
          final workingHours = ref
              .read(userNotifierProvider)
              .realWorkingHours; // Replace with actual user id
          final String productName = newBonus['productName'];
          final double bonus = newBonus['bonus'];
          final int amount = newBonus['amount'];
          final DateTime selectedEventDate = newBonus[
              'selectedDate']; // Replace with actual selected event date

          await ref
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
        onNotification: (notification) {
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
              Row(
                children: [
                  const Row(
                    children: [
                      MonthlyWorkingHours(),
                      MonthlyBonus(),
                    ],
                  ),
                  Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(2),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                15), // This gives the rounded corner for the decoration
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.orange[100]!,
                                Colors.orange[400]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.6),
                                offset: const Offset(4, 4),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                offset: const Offset(-4, -4),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 30,
                            icon: const Icon(Icons.history_outlined),
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                          ),
                        ),
                      )),
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
                          final bonus = event['bonus'] as double;
                          return bonus > 0
                              ? ColoredBox(
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
