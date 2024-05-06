import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestoreDataTile extends ConsumerStatefulWidget {
  const RestoreDataTile({super.key});

  @override
  _RestoreDataTileState createState() => _RestoreDataTileState();
}

class _RestoreDataTileState extends ConsumerState<RestoreDataTile> {
  bool _isLoading = false;

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermission =
          await ref.read(backupManagerProvider.notifier).requestPermissions();
      if (!mounted) return;

      if (hasPermission) {
        await ref.read(backupManagerProvider.notifier).restoreBackup();
        if (!mounted) return;

        await ref.read(bonusInfoListProvider.notifier).refreshHive();
        if (!mounted) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully restored data.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } on FormatException catch (e) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to restore data: $e'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
    } finally {
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

  Future<bool> _showRestoreConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Restoring from backup will overwrite your current data. Are you sure you want to proceed?',
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
      title: const Text(
        'Restore with backup',
        style: TextStyle(fontSize: 16),
      ),
      trailing: _isLoading ? const CircularProgressIndicator() : null,
      onTap: () async => _handleTap(context, ref),
    );
  }
}
