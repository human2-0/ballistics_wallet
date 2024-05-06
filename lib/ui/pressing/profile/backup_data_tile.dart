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
    Future.microtask(
      () async => ref.read(backupManagerProvider.notifier).checkActiveState(),
    );
  }

  bool _isLoading = false;

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final hasPermission =
          await ref.read(backupManagerProvider.notifier).requestPermissions();
      if (hasPermission) {
        await ref.read(backupManagerProvider.notifier).backupData();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully uploaded data.'),
              duration: Duration(seconds: 5),
            ),
          );
        });
      }
    } on FormatException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to back up data: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } finally {
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

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: (ref.watch(backupManagerProvider).isActive && ref.read(userNotifierProvider).backup!)
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
      onTap: () async {
        final confirm = await _showBackUpConfirmationDialog(context);
        await ref.read(userNotifierProvider.notifier).doBackUp(true);
        if (!_isLoading && confirm) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
            await _backupData(context, ref);
            // After backup, you might want to check the active state again
            await ref.read(backupManagerProvider.notifier).checkActiveState();
          });
        }
      },
      trailing: _isLoading ? const CircularProgressIndicator() : null,
    );
  }
}
