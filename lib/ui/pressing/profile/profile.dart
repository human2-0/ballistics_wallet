import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilePage extends StatefulHookConsumerWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authRepo = ref.read(authRepositoryProvider);
    final uid = authRepo.currentUserId;

    final userNotifier = ref.watch(userNotifierProvider.notifier);
    final userState = ref.watch(userNotifierProvider);

    final userDataAsyncValue = ref.watch(userDataProvider(uid));

    final workingHoursController = TextEditingController();
    final hourlyRateController = TextEditingController();

    // Use useEffect to load user data when the widget is first created
    useEffect(
      () {
        Future.microtask(() async => userNotifier.loadUser(uid));
        return null;
      },
      [],
    );

    // Show loading spinner if user data is not yet loaded
    if (userDataAsyncValue is AsyncLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error message if there was an error loading user data
    if (userDataAsyncValue is AsyncError) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading user data'),
                  IconButton(
                    icon: const Icon(
                      color: Colors.orange,
                      Icons.flight_takeoff_outlined,
                    ),
                    onPressed: authRepo.signOut,
                  ),
                  const Text('Log out'),
                ],
              ),
            ),
          ],
        ),
      );
    }


    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange[200],
            ),
            child: IconButton(
              icon: Icon(
                color: Colors.orange[600],
                Icons.flight_takeoff_outlined,
              ),
              onPressed: authRepo.signOut,
            ),
          ),
          Center(
            child: Card(
              color: Colors.lightBlueAccent[100]!.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        userState.avatarUrl ??
                            'https://media.istockphoto.com/id/1207566766/photo/3d-emoji-with-smiley-face.jpg?s=1024x1024&w=is&k=20&c=Xjh-ij_drKQXCsTleoExXAyq-Leb4wraBt36BwPjuso=',
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[200]!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      'Working Hours: ${userState.realWorkingHours}',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      'Hourly Rate: £${userState.hourlyRate}',
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 39,
                                ),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title:
                                          const Text('Edit your information'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: workingHoursController,
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Enter new working hours',
                                            ),
                                          ),
                                          TextField(
                                            controller: hourlyRateController,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter new hourly rate',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Submit'),
                                          onPressed: () async {
                                            final newWorkingHours =
                                                double.parse(
                                              workingHoursController.text,
                                            );
                                            final newHourlyRate = double.parse(
                                              hourlyRateController.text,
                                            );
                                            // await ref
                                            //     .read(userRepositoryProvider)
                                            //     .editWorkingHours(
                                            //       uid,
                                            //       newWorkingHours,
                                            //     );
                                            // await userNotifier.updateUser(
                                            //   UserState(
                                            //     workingHours: newWorkingHours,
                                            //     avatarUrl: userState.avatarUrl,
                                            //   ),
                                            // );
                                            await userNotifier
                                                .editHourlyRate(newHourlyRate);
                                            final result = await userNotifier
                                                .editWorkingHours(
                                                    newWorkingHours,);
                                            if (result) {
                                              await userNotifier.loadUser(uid);
                                            }
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[200]!.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              'Paid breaks',
                            ),
                          ),
                          IconButton(
                            icon: CircleAvatar(
                              radius: 20,
                              backgroundColor: (userState.paidBreaks ?? false)
                                  ? Colors.green
                                  : Colors.grey,
                              child: (userState.paidBreaks ?? false)
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                            onPressed: () async {
                              final success = await ref
                                  .read(userRepositoryProvider)
                                  .editPaidBreaks(
                                    uid,
                                    !(userState.paidBreaks ?? false),
                                  );
                              if (success) {
                                await userNotifier.updateUser(
                                  UserState(
                                    paidBreaks:
                                        !(userState.paidBreaks ?? false),
                                    avatarUrl: userState.avatarUrl,
                                    allowance: userState.allowance,
                                    workingHours: userState.workingHours,
                                    realWorkingHours:
                                        userState.realWorkingHours,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            height: MediaQuery.sizeOf(context).height * 0.33,
            width: MediaQuery.sizeOf(context).width * 0.70,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
                child: Text(
                    'Here will be the chart showing avarage holiday rate',),),
          ),
        ],
      ),
    );
  }
}
