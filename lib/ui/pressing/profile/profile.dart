import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/backup_data_tile.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/edit_user_settings.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/restore_data_tile.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfilePage extends StatefulHookConsumerWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends ConsumerState<ProfilePage> {
  String _versionNumber = '';


  Future<void> _getVersionNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _versionNumber = info.version;
      });
    } on FormatException {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load version number.')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.read(authRepositoryProvider);
    final uid = authRepo.currentUserId;

    final userNotifier = ref.watch(userNotifierProvider.notifier);
    final userState = ref.watch(userNotifierProvider);

    final userDataAsyncValue = ref.watch(userDataProvider(uid));


    // Use useEffect to load user data when the widget is first created
    useEffect(() {
      scheduleMicrotask(()=>userNotifier.loadUser(uid));
      scheduleMicrotask(_getVersionNumber);
      return null;
    }, [uid],);

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
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.3),
      ),
      drawer: Drawer(
        backgroundColor: Colors.orange[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[300],
              ),
              child: const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                0,
                4,
              ),
              child: Text('Account'),
            ),
            const BackUpDataTile(),
            const RestoreDataTile(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                4,
                0,
                4,
              ),
              child: Text('Help Center'),
            ),
            ListTile(
              title: const Text('Report a bug'),
              leading: const Icon(Icons.bug_report_outlined),
              onTap: () async => context.push('/reportbug'),
            ),
            ListTile(
              title: const Text('Ask for a feature'),
              leading: const Icon(Icons.question_answer_outlined),
              onTap: () async => context.push('/askforfeature'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                4,
                0,
                4,
              ),
              child: Text('About'),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              leading: const Icon(Icons.privacy_tip_outlined),
              onTap: () async => context.push('/privacy'),
            ),
            ListTile(
              title: const Text('Terms of Use'),
              leading: const Icon(Icons.newspaper),
              onTap: () async => context.push('/termsofuse'),
            ),
            ListTile(
              title: const Text('Licenses'),
              leading: const Icon(Icons.school_outlined),
              onTap: () async => context.push('/license'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                // Trigger sign out logic
                await authRepo.signOut();
                // Close the drawer
              },
            ),
            ListTile(
              title: const Text(
                'App version',
              ),
              subtitle: Text('Beta $_versionNumber'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.lightBlueAccent[100]!.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          userState.avatarUrl ?? 'http://non-existing.com',
                        ),
                        onBackgroundImageError: (_, __) {
                          debugPrint(_.toString());
                        },
                        child: userState.avatarUrl == null
                            ? const Image(
                                image: AssetImage('assets/default_avatar.webp'),
                              )
                            : null,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[200]!.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        'Daily Schedule: ${formatWorkingHours(userState.realWorkingHours ?? 0.0)}',
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
                                        'Hourly Rate: £${userState.hourlyRate ?? 0}',
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
                                    await showDialog<void>(
                                      context: context,
                                      builder: (context) =>
                                          EditWorkingHoursDialog(
                                        onSubmit: (
                                          newWorkingHours,
                                          newHourlyRate,
                                        ) async {
                                          final result = await userNotifier
                                              .updateUserSettings(
                                            newWorkingHours,
                                            newHourlyRate,
                                          );
                                          if (result) {
                                            await userNotifier.loadUser(uid);
                                          }
                                        },
                                        userState: userState,
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
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[200]!.withValues(alpha: 0.2),
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
                                  backgroundColor:
                                      (userState.paidBreaks ?? false)
                                          ? Colors.green
                                          : Colors.grey,
                                  child: (userState.paidBreaks ?? false)
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
