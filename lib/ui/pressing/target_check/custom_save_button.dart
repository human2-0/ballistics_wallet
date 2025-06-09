import 'package:ballistics_wallet_flutter/custom_widgets/toast_widget.dart';
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
  @override
  Widget build(BuildContext context) {
    final productName =
        ref.watch(focusedProductProvider).productName.toLowerCase().trimRight();
    final amount = int.tryParse(ref.watch(numberControllerProvider)) ?? 0;
    final allowance = ref.watch(allowanceProvider);
    final userState = ref.watch(userNotifierProvider);
    final workingHours = userState.workingHours ?? 0.0;
    return Builder(
      builder: (buttonContext) => LayoutBuilder(
        builder: (
          context,
          constraints,
        ) =>
            Column(
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.60,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Colors.yellowAccent[100],
                  ),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                onPressed: (productName.isEmpty || amount == 0)
                    ? null
                    : () async {
                        final authRepository = ref.read(authRepositoryProvider);
                        final targetRatio =
                            ref.read(bonusInfoListProvider).ratio;
                        final bonusAsyncValue = ref.read(
                          bonusCalculator(
                            targetRatio,
                          ),
                        ); // changed watch to read
                        final userId = authRepository.currentUserId;
                        final bonus = bonusAsyncValue *
                            ((workingHours - allowance) / 7.0);
                        final productRatio = ref
                            .read(
                              bonusInfoListProvider.notifier,
                            )
                            .getProductRatio(
                              productName.toLowerCase().trim(),
                            );
                        final newBonusInfo = BonusInfo(
                          userId: userId, // Replace with actual user ID
                          bonus: bonus,
                          date: DateTime.now(),
                          workingHours: userState.realWorkingHours!,
                          isOvertime: false,
                          produced: [
                            Produced(
                              productName: productName,
                              amount: amount,
                              ratio: productRatio,
                              allowance: allowance,
                            ),
                          ], // Initialize with empty or collect data as needed
                        );

                        final message = await ref
                            .read(bonusInfoListProvider.notifier)
                            .addBonusInfo(newBonusInfo);
                        final backup = ref.read(userNotifierProvider).backup!;
                        final doNotAskAgain =
                            ref.watch(userNotifierProvider).askForBackup;
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) async {
                          if (!backup && !doNotAskAgain!) {
                            await showDialog<Widget>(
                              context: context,
                              builder: (context) {
                                var localDoNotAskAgain = doNotAskAgain;
                                return StatefulBuilder(
                                  builder: (context, setState) => AlertDialog(
                                      title: const Text('Backup Data'),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: <Widget>[
                                            const Text(
                                                'Hey, would you like to start to back up your data? ',
                                            ),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: localDoNotAskAgain,
                                                  onChanged: (value) async {
                                                    setState(() {
                                                      localDoNotAskAgain =
                                                          value!;
                                                    });
                                                    await ref
                                                        .read(
                                                          userNotifierProvider
                                                              .notifier,
                                                        )
                                                        .dontAskAgain(value!);
                                                  },
                                                ),
                                                const Text(
                                                  "Don't ask me again",
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Yes'),
                                          onPressed: () async {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                            await ref
                                                .read(
                                                  backupManagerProvider
                                                      .notifier,
                                                )
                                                .backupData();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('No'),
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                        ),
                                      ],
                                    ),
                                );
                              },
                            );
                          }
                        });
                        if (backup) {
                          await ref
                              .read(backupManagerProvider.notifier)
                              .backupData();
                        }
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          ScaffoldMessenger.of(
                            buttonContext,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                message,
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        });
// Retrieve the bonus value
                      },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
// Center the content horizontally
                  children: [
                    Icon(Icons.wallet),
                    SizedBox(width: 8),

// Add your desired icon
// Add some space between the icon and the text
                    Text('Save to Wallet'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveToWallet({
  required BuildContext context,
  required WidgetRef ref,
  required int amountPressed,
  required bool mounted,
}) async {
  final authRepository = ref.read(authRepositoryProvider);
  final userId = authRepository.currentUserId;
  final productName =
      ref.watch(focusedProductProvider).productName.toLowerCase().trimRight();
  final amount = amountPressed;
  final allowance = ref.watch(allowanceProvider);
  final userState = ref.watch(userNotifierProvider);
  final workingHours = userState.workingHours ?? 0.0;
  final target = ref.watch(targetProvider);

  if (productName.isEmpty || amount == 0) {
    return; // Early return if conditions are not met
  }
  ref
      .read(
        bonusInfoListProvider.notifier,
      )
      .updateRatio(
        productName,
        target,
        amount,
        workingHours,
        allowance,
      );
  final targetRatio = ref.read(bonusInfoListProvider).ratio;
  final bonusAsyncValue =
      ref.read(bonusCalculator(targetRatio)); // changed watch to read
  final bonus = bonusAsyncValue * ((workingHours - allowance) / 7.0);
  final productRatio = ref
      .read(bonusInfoListProvider.notifier)
      .getProductRatio(productName.toLowerCase().trim());

  final newBonusInfo = BonusInfo(
    userId: userId, // Replace with actual user ID
    bonus: bonus,
    date: DateTime.now(),
    workingHours: userState.realWorkingHours!,
    isOvertime: false,
    produced: [
      Produced(
        productName: productName,
        amount: amount,
        ratio: productRatio,
      ),
    ], // Initialize with empty or collect data as needed
  );

  final message =
      await ref.read(bonusInfoListProvider.notifier).addBonusInfo(newBonusInfo);
  final backup = ref.read(userNotifierProvider).backup!;
  final doNotAskAgain = ref.watch(userNotifierProvider).askForBackup;
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
    if (!backup && !doNotAskAgain!) {
      await showDialog<Widget>(
        context: context,
        builder: (context) {
          var localDoNotAskAgain = doNotAskAgain;
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                title: const Text('Backup Data'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      const Text(
                        'Hey, would you like to start to back up your data? ',
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: localDoNotAskAgain,
                            onChanged: (value) async {
                              setState(() {
                                localDoNotAskAgain = value!;
                              });
                              await ref
                                  .read(
                                    userNotifierProvider.notifier,
                                  )
                                  .dontAskAgain(value!);
                            },
                          ),
                          const Text(
                            "Don't ask me again",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close the dialog
                      await ref
                          .read(
                            backupManagerProvider.notifier,
                          )
                          .backupData();
                    },
                  ),
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                ],
              ),
          );
        },
      );
    }
  });
  if (backup) {
    await ref.read(backupManagerProvider.notifier).backupData();
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      showToast(
        context,
        message,
        colors: [Colors.greenAccent, Colors.greenAccent[100]!],
      );
    }
  });
}
