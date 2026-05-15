import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackUpDataTile extends ConsumerStatefulWidget {
  const BackUpDataTile({super.key});

  @override
  _BackUpDataTileState createState() => _BackUpDataTileState();
}

class _BackUpDataTileState extends ConsumerState<BackUpDataTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(backupManagerProvider.notifier).checkActiveState();
    });
  }

  bool _isLoading = false;

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    var retried = false;

    Future<void> showSnack(String text) async {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 5)),
        );
      });
    }

    while (true) {
      try {
        await ref.read(backupManagerProvider.notifier).backupData();
        await ref.read(userNotifierProvider.notifier).doBackUp(true);
        await showSnack('Successfully uploaded data.');
        break;
      } on FormatException catch (e) {
        final msg = e.toString().toLowerCase(); // normalize for matching
        // Decoupled handling: repository throws domain errors; detect by code in message
        if (!retried && msg.contains('notsignedin')) {
          retried = true;
          await ref.read(authRepositoryProvider).signInWithGoogle(); // interactive on tap
          continue; // retry once
        }
        if (!retried && msg.contains('missingdrivescope')) {
          retried = true;
          // Request Drive scope on explicit user action
          await ref.read(authRepositoryProvider).ensureDriveFileScope();
          continue; // retry once
        }
        await showSnack('Failed to back up data: $e');
        break;
      } finally {
        // Refresh the silent UI state regardless of outcome
        await ref.read(backupManagerProvider.notifier).checkActiveState();
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showBackUpConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Back up your data'),
          content: const Text(
            'Backing up your current data will overwrite any other backups from Ballistics app stored in the Google Drive. Are you sure you want to proceed?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(false), // This will close the dialog and return false
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // This will close the dialog and return true
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<bool> _stopBackingUpData(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop back up'),
          content: const Text(
            'Would you like to stop backing up your data to the Google Drive?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pop(false), // This will close the dialog and return false
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // This will close the dialog and return true
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final userData = ref.watch(userNotifierProvider);

    if (!userData.backup!) {
      final confirm = await _showBackUpConfirmationDialog(context);
      if (!_isLoading && confirm) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          await _backupData(context, ref);
          await ref.read(backupManagerProvider.notifier).checkActiveState();
        });
      }
    }

    if (userData.backup!) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final stop = await _stopBackingUpData(context);
        if (stop) {
          await ref.read(userNotifierProvider.notifier).doBackUp(false);
          await ref.read(backupManagerProvider.notifier).checkActiveState();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ref.watch(backupManagerProvider).isActive;
    final isBackupOn = ref.watch(userNotifierProvider).backup ?? false;
    return ListTile(
      leading: (isActive && isBackupOn)
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_done, color: Colors.green),
                Text('in sync'),
              ],
            )
          : const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.cloud_upload_outlined, color: Colors.blue),
            ),
      title: const Text('Back up data'),
      trailing: _isLoading ? const CircularProgressIndicator() : null,
      onTap: () async => _handleTap(context, ref),
    );
  }
}
