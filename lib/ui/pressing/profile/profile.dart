import 'dart:async';

import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/backup_data_tile.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/edit_user_settings.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/restore_data_tile.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/timeline_reminder_settings.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/work_schedule_card.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Shows user settings and account actions.
class ProfilePage extends ConsumerStatefulWidget {
  /// Creates the profile page.
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

/// State for [ProfilePage].
class ProfilePageState extends ConsumerState<ProfilePage> {
  String _versionNumber = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = ref.read(authRepositoryProvider).currentUserId;
      unawaited(ref.read(userNotifierProvider.notifier).loadUser(uid));
      unawaited(_getVersionNumber());
    });
  }

  Future<void> _getVersionNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _versionNumber = info.version;
      });
    } on FormatException {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        showAppNotification(
          context,
          'Could not load version number.',
          type: AppNotificationType.warning,
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
    final dailyScheduleLabel =
        'Daily Schedule: '
        '${formatWorkingHours(userState.realWorkingHours ?? 0.0)}';
    final hourlyRateLabel = 'Hourly Rate: £${userState.hourlyRate ?? 0}';

    final userDataAsyncValue = ref.watch(userDataProvider(uid));

    // Show loading spinner if user data is not yet loaded
    if (userDataAsyncValue is AsyncLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      appBar: AppBar(backgroundColor: Colors.white.withValues(alpha: 0.3)),
      drawer: Drawer(
        backgroundColor: Colors.orange[50],
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange[300]),
              child: const Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 0, 4),
              child: Text('Account'),
            ),
            const ExpansionTile(
              leading: Icon(Icons.cloud_outlined),
              title: Text('Backup & Restore'),
              children: [BackUpDataTile(), RestoreDataTile()],
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: Text('Help Center'),
            ),
            ListTile(
              title: const Text('Report a bug'),
              leading: const Icon(Icons.bug_report_outlined),
              onTap: () => context.push('/reportbug'),
            ),
            ListTile(
              title: const Text('Ask for a feature'),
              leading: const Icon(Icons.question_answer_outlined),
              onTap: () => context.push('/askforfeature'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 0, 4),
              child: Text('About'),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              leading: const Icon(Icons.privacy_tip_outlined),
              onTap: () => context.push('/privacy'),
            ),
            ListTile(
              title: const Text('Terms of Use'),
              leading: const Icon(Icons.newspaper),
              onTap: () => context.push('/termsofuse'),
            ),
            ListTile(
              title: const Text('Licenses'),
              leading: const Icon(Icons.school_outlined),
              onTap: () => context.push('/license'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await authRepo.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('App version'),
              subtitle: Text('Beta $_versionNumber'),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    color: Colors.lightBlueAccent[100]!.withValues(alpha: 0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                userState.avatarUrl == null
                                    ? null
                                    : NetworkImage(userState.avatarUrl!),
                            child:
                                userState.avatarUrl == null
                                    ? const Image(
                                      image: AssetImage(
                                        'assets/default_avatar.webp',
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[200]!.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ProfileInfoChip(
                                        label: dailyScheduleLabel,
                                      ),
                                      _ProfileInfoChip(label: hourlyRateLabel),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 32),
                                  onPressed: () async {
                                    await showDialog<void>(
                                      context: context,
                                      builder:
                                          (context) => EditWorkingHoursDialog(
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
                                                await userNotifier.loadUser(
                                                  uid,
                                                );
                                              }
                                            },
                                            userState: userState,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const WorkScheduleCard(),
                          const SizedBox(height: 8),
                          const TimelineReminderSettings(),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[200]!.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: _ProfileInfoChip(label: 'Paid breaks'),
                                ),
                                IconButton(
                                  icon: CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        (userState.paidBreaks ?? false)
                                            ? Colors.green
                                            : Colors.grey,
                                    child:
                                        (userState.paidBreaks ?? false)
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
                        ],
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

class _ProfileInfoChip extends StatelessWidget {
  const _ProfileInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue[100],
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}
