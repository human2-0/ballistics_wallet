import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestoreDataTile extends ConsumerStatefulWidget {
  const RestoreDataTile({super.key});

  @override
  ConsumerState<RestoreDataTile> createState() => _RestoreDataTileState();
}

class _RestoreDataTileState extends ConsumerState<RestoreDataTile> {
  bool _isLoading = false;

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // helper: show snack later on UI thread
    Future<void> snack(
      String text, {
      AppNotificationType type = AppNotificationType.info,
    }) async {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAppNotification(
          context,
          text,
          type: type,
          duration: const Duration(seconds: 5),
        );
      });
    }

    // Retry-once wrapper: repo stays non-interactive; UI triggers sign-in/scope only if needed
    Future<void> restoreWithRetries() async {
      var retried = false;
      while (true) {
        try {
          // keep your storage permission check here, it's non-interactive
          final hasPermission =
              await ref
                  .read(backupManagerProvider.notifier)
                  .requestPermissions();
          if (!hasPermission) {
            throw const FormatException('Storage permission not granted.');
          }

          await ref
              .read(backupManagerProvider.notifier)
              .restoreBackup(); // non-interactive
          return;
        } catch (e) {
          final msg = e.toString().toLowerCase();
          if (!retried && msg.contains('notsignedin')) {
            retried = true;
            await ref
                .read(authRepositoryProvider)
                .signInWithGoogle(); // interactive on tap
            continue;
          }
          if (!retried && msg.contains('missingdrivescope')) {
            retried = true;
            await ref
                .read(authRepositoryProvider)
                .ensureDriveFileScope(); // interactive on tap
            continue;
          }
          rethrow;
        }
      }
    }

    try {
      await restoreWithRetries();

      // refresh local cache/UI after successful restore
      if (!mounted) return;
      await ref.read(bonusInfoListProvider.notifier).refreshHive();

      await snack('Data restored.', type: AppNotificationType.success);
    } on FormatException catch (e) {
      await snack(
        'Failed to restore data: $e',
        type: AppNotificationType.error,
      );
    } finally {
      // Always refresh the silent active state to keep icons accurate
      await ref.read(backupManagerProvider.notifier).checkActiveState();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final confirm = await _showRestoreConfirmationDialog(context);
    if (confirm) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        await _restoreData(context, ref);
        await ref.read(backupManagerProvider.notifier).checkActiveState();
      });
    }
  }

  Future<bool> _showRestoreConfirmationDialog(
    BuildContext context,
  ) => showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Restoring from backup will overwrite your current data. Are you sure you want to proceed?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed:
                  () => Navigator.of(
                    context,
                  ).pop(false), // This will close the dialog and return false
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(true); // This will close the dialog and return true
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
  ).then((value) => value ?? false);

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
    title: const Text('Restore with backup', style: TextStyle(fontSize: 16)),
    trailing: _isLoading ? const CircularProgressIndicator() : null,
    onTap: () => _handleTap(context, ref),
  );
}
