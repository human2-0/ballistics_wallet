import 'dart:async';

import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
import 'package:ballistics_wallet_flutter/models/bonus_info.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/back_up_provider.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_providers.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomSaveButton extends ConsumerStatefulWidget {
  const CustomSaveButton({super.key});

  @override
  CustomSaveButtonState createState() => CustomSaveButtonState();
}

class CustomSaveButtonState extends ConsumerState<CustomSaveButton> {
  String? _successMessage;
  // Shows a spinner while the save request is in‑flight
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final productName =
        ref.watch(focusedProductProvider).productName.toLowerCase().trimRight();
    final amount = int.tryParse(ref.watch(numberControllerProvider)) ?? 0;
    // final allowance = ref.watch(allowanceProvider);
    // final userState = ref.watch(userNotifierProvider);
    // final workingHours = userState.workingHours ?? 0.0;
    return Builder(
      builder: (buttonContext) => LayoutBuilder(
        builder: (
          context,
          constraints,
        ) =>
            Column(
          children: [
            DecoratedBox(
              decoration: _successMessage != null
                  ? boxDecoration(color: Colors.green)
                  : boxDecoration(),
              child: SizedBox(
                width: constraints.maxWidth * 0.60,
                child: Material(
                  color: _successMessage != null
                      ? Colors.green
                      : (productName.isEmpty || amount == 0 || _isSaving)
                          ? Colors.yellow.shade200
                          : Colors.yellow.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: (productName.isEmpty || amount == 0 || _isSaving)
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            final message = await saveToWallet(
                              context: buttonContext,
                              ref: ref,
                              amountPressed: amount,
                            );
                            if (!mounted) return;
                            setState(() {
                              _isSaving = false;
                              _successMessage = message;
                            });
                            Timer(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _successMessage = null);
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isSaving
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_successMessage != null
                              ? Text(
                                  _successMessage!,
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.wallet, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save to Wallet',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> saveToWallet({
  required BuildContext context,
  required WidgetRef ref,
  required int amountPressed,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  // --- locals / reads (no interactive calls here) ---
  final authRepository = ref.read(authRepositoryProvider);
  final userId = authRepository.currentUserId; // ok: doesn’t prompt
  final productName = ref.watch(focusedProductProvider).productName.toLowerCase().trimRight();
  final amount = amountPressed;
  final allowance = ref.watch(allowanceProvider);
  final userState = ref.watch(userNotifierProvider);
  final workingHours = userState.workingHours ?? 0.0;
  final target = ref.watch(targetProvider);

  if (productName.isEmpty || amount == 0) {
    return '';
  }

  // --- app logic ---
  ref.read(bonusInfoListProvider.notifier).updateRatio(
    productName,
    target,
    amount,
    workingHours,
    allowance,
  );
  final targetRatio = ref.read(bonusInfoListProvider).ratio;
  final bonus = ref.read(bonusCalculator(targetRatio)) * ((workingHours - allowance) / 7.0);
  final productRatio = ref.read(bonusInfoListProvider.notifier).getProductRatio(
    productName.toLowerCase().trim(),
  );

  final newBonusInfo = BonusInfo(
    userId: userId,
    bonus: bonus,
    date: DateTime.now(),
    workingHours: userState.realWorkingHours!,
    isOvertime: false,
    produced: [
      Produced(productName: productName, amount: amount, ratio: productRatio),
    ],
  );

  final message = await ref.read(bonusInfoListProvider.notifier).addBonusInfo(newBonusInfo);

  // --- backup helpers (UI layer handles interactive only on demand) ---
  Future<void> runBackupWithRetries() async {
    var retried = false;
    while (true) {
      try {
        await ref.read(backupManagerProvider.notifier).backupData(); // non-interactive repo call
        return;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (!retried && msg.contains('notsignedin')) {
          retried = true;
          // interactive – user tap pathway
          await ref.read(authRepositoryProvider).signInWithGoogle();
          continue;
        }
        if (!retried && msg.contains('missingdrivescope')) {
          retried = true;
          // interactive – user tap pathway
          await ref.read(authRepositoryProvider).ensureDriveFileScope();
          continue;
        }
        rethrow;
      }
    }
  }

  final backup = ref.read(userNotifierProvider).backup ?? false;
  final doNotAskAgain = ref.watch(userNotifierProvider).askForBackup ?? false;

  // If backup isn’t enabled and the user hasn’t opted out, ask once
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!backup && !doNotAskAgain) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          var localDoNotAskAgain = doNotAskAgain;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Backup Data'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Hey, would you like to start to back up your data?'),
                    Row(
                      children: [
                        Checkbox(
                          value: localDoNotAskAgain,
                          onChanged: (value) async {
                            final v = value ?? false;
                            setState(() => localDoNotAskAgain = v);
                            await ref.read(userNotifierProvider.notifier).dontAskAgain(v);
                          },
                        ),
                        const Text("Don't ask me again"),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await runBackupWithRetries(); // may trigger interactive flow once
                      await ref.read(userNotifierProvider.notifier).doBackUp(true);
                      await ref.read(backupManagerProvider.notifier).checkActiveState();
                      messenger?.showSnackBar(
                        const SnackBar(content: Text('Successfully uploaded data.'), duration: Duration(seconds: 5)),
                      );
                    } on FormatException catch (e) {
                      messenger?.showSnackBar(
                        SnackBar(content: Text('Failed to back up data: $e'), duration: const Duration(seconds: 5)),
                      );
                    }
                  },
                ),
                TextButton(
                  child: const Text('No'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        },
      );
    }
  });

  // If backup is already on, back up silently (interactive only if required)
  if (backup) {
    try {
      await runBackupWithRetries();
      await ref.read(backupManagerProvider.notifier).checkActiveState();
    } on FormatException catch (e) {
      // Keep UX quiet here; backup will try again next time.
      // Optionally toast:
      messenger?.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  return message;
}
