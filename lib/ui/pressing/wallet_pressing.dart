import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_repository.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';

class BonusCalendar extends HookConsumerWidget {
  final String userId;
  final Function(ScrollNotification) onNotification; // Add ScrollController

  const BonusCalendar({required this.userId, required this.onNotification})
      : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _calendarFormat = useState(CalendarFormat.month);
    final _focusedDay = useState(DateTime.now());
    final _selectedDay = useState<DateTime?>(null);
    final _selectedEvents = useState<List<dynamic>>([]);

    final userBonuses = ref.watch(userBonusNotifierProvider);

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
        final childBonus = _selectedEvents.value[parentIndex]['produced'][childIndex];

        // Get the ID of the child bonus
        final childId = childBonus['id'];

        // Perform the delete operation in the background
        ref.read(userBonusNotifierProvider.notifier)
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
          String userId = ref
              .watch(authRepositoryProvider)
              .currentUserId;
          double? workingHours = ref.read(userNotifierProvider).workingHours;// Replace with actual user id
          String productName = newBonus['productName'];
          double bonus = newBonus['bonus'];
          int amount = newBonus['amount'];
          DateTime selectedEventDate = newBonus[
              'selectedDate']; // Replace with actual selected event date

          ref
              .read(userBonusNotifierProvider.notifier)
              .saveUserBonusCalendar(
                  userId, productName, bonus, amount, selectedEventDate, workingHours!)
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

    num getBonusForMonth(
        DateTime month, Map<DateTime, List<dynamic>> userBonuses) {
      num monthlyBonus = 0;

      // Get dates for the range
      final startDate =
          DateTime(month.year, month.month - 1, 19); // 19th of last month
      final endDate =
          DateTime(month.year, month.month, 18); // 18th of this month

      // Iterate over all bonuses
      for (var entry in userBonuses.entries) {
        final date = entry.key;
        final bonuses = entry.value;

        // Check if the date of the bonuses is within the range
        if (date.isAfter(startDate) && date.isBefore(endDate)) {
          // If the date is within range, sum up the bonuses
          for (var bonus in bonuses) {
            monthlyBonus += (bonus['bonus'] ?? 0);
          }
        }
      }

      return monthlyBonus;
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
                          final now = DateTime.now();
                          final userBonuses =
                              ref.watch(userBonusNotifierProvider);

                          Map<String, num> bonuses = {};

                          for (int i = 0; i < 6; i++) {
                            DateTime month = DateTime(now.year, now.month - i);
                            num bonusForMonth =
                                getBonusForMonth(month, userBonuses);

                            String monthName =
                                DateFormat('MMMM yyyy').format(month);
                            String period =
                                '19 ${DateFormat('MMMM yyyy').format(month.subtract(const Duration(days: 30)))} - 18 $monthName';

                            bonuses[period] = bonusForMonth;
                          }

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
      endDrawer: BonusDetailsDrawer(onNotification: onNotification),
    );
  }

  Future<void> _fetchUserBonuses(WidgetRef ref) async {
    final pressingRepository = ref.read(pressingRepositoryProvider);
    final userBonusesNotifier = ref.read(userBonusNotifierProvider.notifier);

    Map<DateTime, List<dynamic>> userBonuses =
        await pressingRepository.fetchUserBonuses(userId);

    // To debug and see if data is fetched

    userBonusesNotifier.setUserBonuses(userBonuses);
  }
}

class MonthlyBonus extends ConsumerWidget {
  const MonthlyBonus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonuses = ref.watch(userBonusNotifierProvider);
    double monthlyBonus = 0;

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
    for (var entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if ((date.compareTo(startDate) >= 0) && (date.compareTo(endDate) <= 0)) {
        // If the date is within range, sum up the bonuses
        for (var bonus in bonuses) {
          monthlyBonus += (bonus['bonus'] ?? 0);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.1,
        child: Container(
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

class MonthlyWorkingHours extends ConsumerWidget {
  const MonthlyWorkingHours({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonuses = ref.watch(userBonusNotifierProvider);
    double monthlyWorkingHours = ref.watch(monthlyWorkingHoursProvider);

    // Get dates for the range
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    // Check the current date to set the date range
    if (now.day >= 20) {
      startDate = DateTime(now.year, now.month, 19);
      endDate = DateTime(now.year, now.month + 1, 18);
    } else {
      startDate = DateTime(now.year, now.month - 1, 19);
      endDate = DateTime(now.year, now.month, 18);
    }

    // Iterate over all bonuses
    for (var entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if ((date.compareTo(startDate) >= 0) && (date.compareTo(endDate) <= 0)) {
        // If the date is within range, sum up the hours
        for (var bonus in bonuses) {
          monthlyWorkingHours += (bonus['workingHours'] ?? 0.0);
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.40,
        height: MediaQuery.of(context).size.height * 0.1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(33)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.6, 0.8, 0.9],
              colors: [
                Colors.blue[400]!.withOpacity(0.6),
                Colors.blue[300]!,
                Colors.blue[200]!,
                Colors.blue[100]!,
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
                  'Total hours\n ${formatDouble(monthlyWorkingHours)}',
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

class BonusDetailsDrawer extends HookConsumerWidget {
  final Function(ScrollNotification) onNotification;

  const BonusDetailsDrawer({Key? key, required this.onNotification})
      : super(key: key);

  double calculateTotalBonus(Map<DateTime, List<dynamic>> userBonuses,
      DateTime startDate, DateTime endDate) {
    double totalBonus = 0;

    // Iterate over all bonuses
    for (var entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        // If the date is within range, sum up the bonuses
        for (var bonus in bonuses) {
          totalBonus += (bonus['bonus'] as num? ?? 0);
        }
      }
    }

    return totalBonus;
  }

  double calculateTotalHours(Map<DateTime, List<dynamic>> userBonuses,
      DateTime startDate, DateTime endDate) {
    double totalHours = 0;

    // Iterate over all bonuses
    for (var entry in userBonuses.entries) {
      final date = entry.key;
      final bonuses = entry.value;

      // Check if the date of the bonuses is within the range
      if (date.isAfter(startDate) && date.isBefore(endDate)) {
        // If the date is within range, sum up the hours
        for (var bonus in bonuses) {
          totalHours += (bonus['workingHours'] as num? ?? 0);
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
      onNotification: (ScrollNotification notification) {
        onNotification(notification);
        return true;
      },
      child: Drawer(
        backgroundColor: Colors.tealAccent[100],
        child: ListView.separated(
          itemCount: 12,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 8), // adds space between the items
          itemBuilder: (context, index) {
            DateTime monthStart = DateTime(now.year, now.month - index, 19);
            DateTime monthEnd = DateTime(now.year, now.month - index + 1, 18);

            double totalBonusForMonth =
                calculateTotalBonus(bonuses, monthStart, monthEnd);

            double totalHoursForMonth = calculateTotalHours(bonuses, monthStart, monthEnd);

            String period =
                '${DateFormat('MMMM yyyy').format(monthStart)} - ${DateFormat('MMMM yyyy').format(monthEnd)}';

            return Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(33),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal[500]!.withOpacity(0.6),
                      offset: const Offset(10, 10),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      offset: const Offset(-5, -5),
                      blurRadius: 15,
                      spreadRadius: -5,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.1, 0.5, 0.7, 0.9],
                    colors: [
                      Colors.teal[200]!.withOpacity(1),
                      Colors.teal[300]!,
                      Colors.teal.withOpacity(0.6),
                      Colors.teal.withOpacity(0.5),
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
                    'Total bonus: £${totalBonusForMonth}\n Total Hours: ${totalHoursForMonth} ',
                    style: const TextStyle(
                        color: Colors.white70), // adjusts the subtitle color
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BonusListView extends HookConsumerWidget {
  final List<Map<String, dynamic>> selectedEvents;
  final DateTime selectedDate;
  final String userId;
  final Function onDelete;
  final Function(Map<String, dynamic>) onAdd;


  const BonusListView({
    required this.selectedEvents,
    required this.selectedDate,
    required this.userId,
    required this.onDelete,
    required this.onAdd,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);
    final userBonuses = ref.watch(userBonusNotifierProvider);

    // Fetch bonuses on initial render
    useEffect(() {
      userBonusNotifier.fetchUserBonuses(userId);
      return null;
    }, const []);


    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: selectedEvents.length + 1, // Add 1 for the AddBonusListItem
      itemBuilder: (context, index) {
        // If the index is the last item, return the AddBonusListItem
        if (index == selectedEvents.length) {
          return AddBonusListItem(
            onAdd: onAdd,
            selectedDate: selectedDate,
            userId: userId,
          );
        }
        // Otherwise, render the BonusListItem
        final event = selectedEvents[index];
        final userBonuses = ref.watch(userBonusNotifierProvider);
        return Dismissible(
          key: Key(event['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              onDelete(index,0);
              await ref.read(userBonusNotifierProvider.notifier).deleteUserBonus(event['id'], userId);
              // Update the list immediately after deleting an item
              useState(() {
                selectedEvents.removeAt(index);
              });
              await ref.read(targetRatioProvider(userId).notifier).init();
              return true;
            }
            return false;
          },
          secondaryBackground: ClipRRect(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(33.0),
                bottomRight: Radius.circular(33.0)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(33.0),
                    bottomRight: Radius.circular(33.0)),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.red, Colors.deepPurple.shade900],
                ),
              ),
            child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
          ),
          child: BonusListItem(
            date: selectedDate,
            index: index,
            event: event,
            userId: userId,
            onDelete: onDelete,
            parentIndex: index,
          ),
        );
      },
    );
  }
}

class BonusListItem extends HookConsumerWidget {
  final DateTime date;
  final int index;
  final Map<String, dynamic> event;
  final String userId;
  final Function? onDelete;
  final int parentIndex;

  const BonusListItem({
    required this.date,
    required this.index,
    required this.event,
    required this.userId,
    this.onDelete,
    required this.parentIndex,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newProductNameController = useTextEditingController();
    final newProductAmountController = useTextEditingController();

    // Ensure that produced is not null
    final produced = event['produced'] ?? []; // List of produced items

    final isEditing = useState(false);
    final newBonusAmountController =
        useTextEditingController(text: '${event['bonus']}');
    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);

    final primaryColor = (event['isOvertime'] != null && event['isOvertime'])
        ? Colors.blue
        : Colors.orange;


    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(33)),
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
              offset: const Offset(10, 10),
              blurRadius: 10,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              offset: const Offset(-5, -5),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Add this line to center the row
                children: [
                  Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(33),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor[500]!.withOpacity(0.6),
                                offset: const Offset(10, 10),
                                blurRadius: 10,
                                spreadRadius: -5,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.4),
                                offset: const Offset(-5, -5),
                                blurRadius: 15,
                                spreadRadius: -5,
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.1, 0.5, 0.7, 0.9],
                              colors: [
                                primaryColor.withOpacity(0.4),
                                primaryColor[300]!,
                                primaryColor.withOpacity(0.5),
                                primaryColor.withOpacity(0.01),
                              ],
                            ),
                            color: Colors.white,
                          ),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.17,
                            height: MediaQuery.of(context).size.height * 0.09,
                            child: Center(
                                child: Text(
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    'Hours\n    ${formatDouble(event['workingHours'] ?? 0.0)}')),
                          ))),
                  GestureDetector(
                    onTap: () {
                      isEditing.value = !isEditing.value; // toggle editing mode
                      if (isEditing.value) {
                        newBonusAmountController.text =
                            formatDouble(event['bonus']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor[500]!.withOpacity(0.6),
                              offset: const Offset(10, 10),
                              blurRadius: 10,
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              offset: const Offset(-5, -5),
                              blurRadius: 15,
                              spreadRadius: -5,
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.1, 0.5, 0.7, 0.9],
                            colors: [
                              primaryColor.withOpacity(0.4),
                              primaryColor[300]!,
                              primaryColor.withOpacity(0.5),
                              primaryColor.withOpacity(0.01),
                            ],
                          ),
                          color: Colors.white,
                        ),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: MediaQuery.of(context).size.height * 0.09,
                          child: Stack(
                            children: [
                              Center(
                                child: isEditing.value
                                    ? TextField(
                                        controller: newBonusAmountController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        '£${formatDouble(event['bonus'])}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              if (isEditing.value) ...[
                                Positioned(
                                  left: -10,
                                  top: -10,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      ref
                                          .read(userBonusNotifierProvider
                                              .notifier)
                                          .deleteUserBonus(event['id'], userId)
                                          .then((_) {
                                        event['bonus'] = 0;
                                        isEditing.value = false;
                                        newBonusAmountController.clear();

                                        // Only call init() after the delete operation has completed.
                                        ref
                                            .read(targetRatioProvider(userId)
                                                .notifier)
                                            .init();
                                      });
                                    },
                                  ),
                                ),
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    onPressed: () async {
                                      double? newBonusAmount = double.tryParse(
                                          newBonusAmountController.text);
                                      if (newBonusAmount != null) {
                                        await ref
                                            .read(userBonusNotifierProvider
                                                .notifier)
                                            .editBonus(userId, event['id'],
                                                newBonusAmount);
                                        event['bonus'] = newBonusAmount;
                                        isEditing.value = false;
                                        newBonusAmountController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: produced.length,
                          itemBuilder: (context, i) {
                            final item = produced[i];
                            return ListTile(
                              title: Text(item['productName']),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Amount: ${item['amount']}'),
                                ],
                              ),
                              trailing: IconButton(
                                  color: Colors.red,
                                  icon: Icon(
                                      color: Colors.pink[50],
                                      Icons.delete_outline),
                                  onPressed: () {
                                    onDelete?.call(parentIndex, index);
                                    ref
                                        .read(targetRatioProvider(userId)
                                            .notifier)
                                        .init();
                                  }),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 115, 0),
                          child: TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (BuildContext context) {
                                  return AnimatedPadding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom,
                                      ),
                                      duration:
                                          const Duration(milliseconds: 100),
                                      child: SingleChildScrollView(
                                          child: Container(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const Text(
                                              'Add Product',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 24.0,
                                              ),
                                            ),
                                            const SizedBox(height: 16.0),
                                            FutureBuilder<
                                                    List<Map<String, dynamic>>>(
                                                future: ref
                                                    .watch(
                                                        pressingRepositoryProvider)
                                                    .readProductsPressing(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    List<String> productList =
                                                        snapshot.data!
                                                            .map((product) =>
                                                                product['name']
                                                                    .toString())
                                                            .toList();
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          Radius.circular(33),
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.orange
                                                                .withOpacity(1),
                                                            offset:
                                                                const Offset(
                                                                    2, -2.5),
                                                          ),
                                                        ],
                                                      ),
                                                      child: TypeAheadField(
                                                        textFieldConfiguration:
                                                            TextFieldConfiguration(
                                                          controller:
                                                              newProductNameController,
                                                          decoration:
                                                              InputDecoration(
                                                            alignLabelWithHint:
                                                                true,
                                                            hintText:
                                                                'Product Name',
                                                            filled: true,
                                                            fillColor: Colors
                                                                .orange[100],
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          33),
                                                              borderSide:
                                                                  BorderSide
                                                                      .none,
                                                            ),
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        suggestionsCallback:
                                                            (pattern) {
                                                          return productList
                                                              .where((product) => product
                                                                  .toLowerCase()
                                                                  .contains(pattern
                                                                      .toLowerCase()))
                                                              .toList();
                                                        },
                                                        itemBuilder: (context,
                                                            suggestion) {
                                                          return ListTile(
                                                            title: Text(
                                                                suggestion),
                                                          );
                                                        },
                                                        onSuggestionSelected:
                                                            (suggestion) {
                                                          newProductNameController
                                                                  .text =
                                                              suggestion;
                                                        },
                                                        noItemsFoundBuilder:
                                                            (context) => const Text(
                                                                'No matches found'),
                                                      ),
                                                    );
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return Text(
                                                        'Error: ${snapshot.error}');
                                                  }
                                                  // Show a loading indicator while waiting for the products
                                                  return const CircularProgressIndicator();
                                                }),
                                            const SizedBox(height: 8.0),
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(33),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orange
                                                        .withOpacity(1),
                                                    offset:
                                                        const Offset(2, -2.5),
                                                  ),
                                                ],
                                              ),
                                              child: TextField(
                                                controller:
                                                    newProductAmountController,
                                                decoration: InputDecoration(
                                                  alignLabelWithHint: true,
                                                  hintText: 'Amount',
                                                  filled: true,
                                                  fillColor: Colors.orange[100],
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            33),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ),
                                            const SizedBox(height: 16.0),

                                            const SizedBox(height: 16.0),
                                            Center(
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          Colors.tealAccent),
                                                  shadowColor:
                                                      MaterialStateProperty.all(
                                                          Colors.tealAccent),
                                                  elevation:
                                                      MaterialStateProperty.all(
                                                          10), // adjust for desired shadow effect
                                                  shape:
                                                      MaterialStateProperty.all<
                                                          RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18.0),
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  final bonusNotifier = ref.read(
                                                      userBonusNotifierProvider
                                                          .notifier);
                                                  final ratioNotifier = ref
                                                      .read(targetRatioProvider(
                                                              userId)
                                                          .notifier);
                                                  String newProductName =
                                                      newProductNameController
                                                          .text;
                                                  int? newProductAmount =
                                                      int.tryParse(
                                                          newProductAmountController
                                                              .text);

                                                  double? workingHours = ref.read(userNotifierProvider).workingHours;

                                                  if ((newProductName
                                                          .isNotEmpty &&
                                                      newProductAmount !=
                                                          null)) {
                                                    await userBonusNotifier
                                                        .saveUserBonusCalendar(
                                                      userId,
                                                      newProductName, // if null, set to 0
                                                      0,
                                                      newProductAmount,
                                                      date,
                                                      workingHours!,
                                                    );
                                                    ref
                                                        .read(
                                                            targetRatioProvider(
                                                                    userId)
                                                                .notifier)
                                                        .init();
                                                    newProductNameController
                                                        .clear();
                                                    newProductAmountController
                                                        .clear();
                                                    Navigator.of(context)
                                                        .pop(); // close the sheet
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Please provide more data')));
                                                  }
                                                },
                                                child: const Text(
                                                    style: TextStyle(
                                                      color: Colors.brown,
                                                    ),
                                                    'Save'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )));
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor[100]!,
                                    primaryColor[200]!
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.6),
                                    offset: const Offset(7, 9),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    offset: const Offset(-2, -4),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                  ),
                                ],
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddBonusListItem extends HookConsumerWidget {
  final Function(Map<String, dynamic>) onAdd;
  final DateTime selectedDate;
  final String userId;

  const AddBonusListItem({
    required this.onAdd,
    required this.selectedDate,
    required this.userId,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newBonusAmountController = ref.watch(bonusAmountControllerProvider);
    final newProductNameController = ref.watch(productNameControllerProvider);
    final overtimeHoursController = ref.watch(overtimeHoursControllerProvider);
    final newProductAmountController =
        ref.watch(productAmountControllerProvider);
    final nameFocusNode = useFocusNode();
    final amountFocusNode = useFocusNode();

    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);

    final isOvertime = useState(false);

    return Padding(
      padding: const EdgeInsets.all(30),
      child: TextButton(
        onPressed: () {
          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery
                          .of(context)
                          .viewInsets
                          .bottom,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            'Add Bonus',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24.0,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(33),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(1),
                                  offset: const Offset(2, -2.5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: newBonusAmountController,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                hintText: 'Bonus',
                                filled: true,
                                fillColor: Colors.orange[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(33),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: ref
                                .watch(pressingRepositoryProvider)
                                .readProductsPressing(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                List<String> productList = snapshot.data!
                                    .map((product) =>
                                    product['name'].toString())
                                    .toList();
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(33),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(1),
                                        offset: const Offset(2, -2.5),
                                      ),
                                    ],
                                  ),
                                  child: TypeAheadFormField<String>(
                                    textFieldConfiguration: TextFieldConfiguration(
                                      controller: newProductNameController,
                                      decoration: InputDecoration(
                                        alignLabelWithHint: true,
                                        hintText: 'Product Name',
                                        filled: true,
                                        fillColor: Colors.orange[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              33),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    suggestionsCallback: (pattern) {
                                      return productList
                                          .where((product) =>
                                          product
                                              .toLowerCase()
                                              .contains(pattern.toLowerCase()))
                                          .toList();
                                    },
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      newProductNameController.text =
                                          suggestion;
                                    },
                                    noItemsFoundBuilder: (context) =>
                                    const Text('No matches found'),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }
                              // Show a loading indicator while waiting for the products
                              return const CircularProgressIndicator();
                            },
                          ),
                          const SizedBox(height: 8.0),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(33),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(1),
                                  offset: const Offset(2, -2.5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: newProductAmountController,
                              decoration: InputDecoration(
                                alignLabelWithHint: true,
                                hintText: 'Amount',
                                filled: true,
                                fillColor: Colors.orange[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(33),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: SwitchListTile(
                              title: const Text('Overtime'),
                              value: isOvertime.value,
                              onChanged: (bool value) {
                                setState(() {
                                  isOvertime.value = value;
                                });
                              },
                              secondary: const Icon(Icons.access_time),
                            ),
                          ),
                          if (isOvertime.value)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(33),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(1),
                                    offset: const Offset(2, -2.5),
                                  ),
                                ],
                              ),
                              child: TextField(controller: overtimeHoursController,
                                decoration: InputDecoration(
                                  alignLabelWithHint: true,
                                  hintText: 'Overtime hours',
                                  filled: true,
                                  fillColor: Colors.orange[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(33),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          const SizedBox(height: 16.0),
                          Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                MaterialStateProperty.all(Colors.tealAccent),
                                shadowColor:
                                MaterialStateProperty.all(Colors.tealAccent),
                                elevation: MaterialStateProperty.all(
                                    10), // adjust for desired shadow effect
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                              ),
                              focusNode: amountFocusNode,
                              onPressed: () async {
                                FocusScope.of(context).unfocus();

                                double? bonusAmount =
                                double.tryParse(newBonusAmountController.text);
                                String productName = newProductNameController
                                    .text;
                                int? productAmount =
                                int.tryParse(newProductAmountController.text);
                                double? workingHours = isOvertime.value
                                    ? double.tryParse(overtimeHoursController.text)
                                    : ref
                                    .read(userNotifierProvider)
                                    .workingHours;




                                if ((bonusAmount != null) ||
                                    (productName.isNotEmpty &&
                                        productAmount != null)) {
                                  // Clear the TextFields here before initiating the async operations.

                                  // Use `await` instead of `then` to ensure that the next operation doesn't start until this one is done.
                                  await userBonusNotifier.saveUserBonusCalendar(
                                    userId,
                                    productName,
                                    bonusAmount ?? 0,
                                    productAmount ?? 0,
                                    selectedDate,
                                    workingHours!,
                                    isOvertime: isOvertime.value,
                                  );

                                  // This code will only run after saveUserBonusCalendar() has finished.

                                  newBonusAmountController.clear();
                                  newProductNameController.clear();
                                  newProductAmountController.clear();
                                  overtimeHoursController.clear();

                                  // Close the sheet after all operations are done.
                                  Navigator.of(context).pop();
                                  ref
                                      .read(
                                      targetRatioProvider(userId).notifier)
                                      .init();
                                } else {
                                  // Close the sheet if the data validation fails.
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber,
                Colors.orange!,

              ],
              stops: const [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlueAccent.withOpacity(0.7),
                offset: const Offset(5, 10), // Increase the offset for a deeper look
                blurRadius: 27, // Increase the blur radius for a softer shadow
                spreadRadius: 4, // Increase the spread radius for a more intense shadow
              ),
            ],
            borderRadius: const BorderRadius.all(
              Radius.circular(18),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.brown,
            ),
          ),
        ),
      ),
    );
  }
}


class BonusDetailsScreen extends StatelessWidget {
  final Map<String, num> bonuses;

  const BonusDetailsScreen({required this.bonuses});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bonus Details'),
      ),
      body: const Center(
          child: Text('Main Page')), // Your main page widget goes here
      endDrawer: Drawer(
        child: ListView.builder(
          itemCount: bonuses.length,
          itemBuilder: (context, index) {
            String key = bonuses.keys.elementAt(index);
            return ListTile(
              title: Text('$key: ${bonuses[key]}'),
            );
          },
        ),
      ),
    );
  }
}

class TextFieldStateNotifier extends StateNotifier<TextEditingController> {
  TextFieldStateNotifier(String initialValue)
      : super(TextEditingController(text: initialValue));

  void setText(String value) {
    state.text = value;
  }
}

final bonusAmountControllerProvider =
    StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
  (ref) => TextFieldStateNotifier(''),
);

final productNameControllerProvider =
    StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
  (ref) => TextFieldStateNotifier(''),
);

final productAmountControllerProvider =
    StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
  (ref) => TextFieldStateNotifier(''),
);

final overtimeHoursControllerProvider =
StateNotifierProvider<TextFieldStateNotifier, TextEditingController>(
      (ref) => TextFieldStateNotifier(''),
);

final monthlyBonusProvider = Provider<int>((ref) {
  final userBonusesNotifier = ref.watch(userBonusesProvider.notifier);
  return userBonusesNotifier.calculateMonthlyBonus();
});

final ratioCalendar = StateProvider<double>((ref){
  return 0.0;
});


