import 'package:flutter/material.dart';
import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);
    final uid = authRepo.currentUserId;

    final userNotifier = ref.watch(userNotifierProvider.notifier);
    final userState = ref.watch(userNotifierProvider);

    final userDataAsyncValue = ref.watch(userDataProvider(uid));

    final TextEditingController controller = TextEditingController();

    // Use useEffect to load user data when the widget is first created
    useEffect(() {
      userNotifier.loadUser(uid);
      return null;  // Return a null cleanup function because we don't need to cleanup anything
    }, []);

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
      return const Scaffold(
        body: Center(
          child: Text("Error loading user data"),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/profile_screen.jpg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(

                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(userState.avatarUrl ?? 'https://media.istockphoto.com/id/1207566766/photo/3d-emoji-with-smiley-face.jpg?s=1024x1024&w=is&k=20&c=Xjh-ij_drKQXCsTleoExXAyq-Leb4wraBt36BwPjuso='),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 20),
                              Text("Working Hours: ${userState.realWorkingHours}"),
                              const SizedBox(height: 10),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Edit Working Hours"),
                                        content: TextField(
                                          controller: controller,
                                          decoration: const InputDecoration(
                                            hintText: "Enter new working hours",
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Submit"),
                                            onPressed: () async {
                                              double newWorkingHours =
                                                  double.parse(controller.text);
                                              bool success = await ref
                                                  .read(userRepositoryProvider)
                                                  .editWorkingHours(
                                                      uid, newWorkingHours);
                                              if (success) {
                                                userNotifier.updateUser(UserState(
                                                  workingHours: newWorkingHours,
                                                  avatarUrl: userState.avatarUrl,
                                                ));
                                              }
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Paid breaks"),
                              IconButton(
                                icon: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: userState.paidBreaks == true ? Colors.green : Colors.grey,
                                  child: userState.paidBreaks == true ? Icon(Icons.check, color: Colors.white) : null,
                                ),
                                onPressed: () async {
                                  bool success = await ref
                                      .read(userRepositoryProvider)
                                      .editPaidBreaks(uid, !(userState.paidBreaks ?? false));
                                  if (success) {
                                    userNotifier.updateUser(UserState(
                                      paidBreaks: !(userState.paidBreaks ?? false),
                                      avatarUrl: userState.avatarUrl,
                                      allowance: userState.allowance,
                                      workingHours: userState.workingHours,
                                      realWorkingHours: userState.realWorkingHours,
                                    ));

                                  }
                                },
                              ),

                            ],
                          ),
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.orange[200],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        color: Colors.orange,
                                        Icons.flight_takeoff_outlined),
                                    onPressed: () {
                                      authRepo.signOut();
                                    },
                                  ),
                                  const Text("Log out"),
                                ],
                              ),
                            ),
                          ),



                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
