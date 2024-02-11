import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomSaveButton extends ConsumerStatefulWidget{
  const CustomSaveButton({super.key});

  @override
  CustomSaveButtonState createState() => CustomSaveButtonState();
}


class CustomSaveButtonState extends ConsumerState<CustomSaveButton> {


  @override
    Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).currentUserId;
    final targetRatio = ref.watch(targetRatioProvider(userId));
    final productName =
    ref.watch(selectedProductProvider).state.toLowerCase().trimRight();
    final amount = ref.watch(numberProvider);
    final allowance = ref.watch(allowanceProvider);
    final userState = ref.watch(userNotifierProvider);
    final workingHours = userState.workingHours ?? 0.0;
    return Builder(
      builder: (buttonContext) => LayoutBuilder(builder: (context,
            constraints,) => Column(
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.60,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(
                        Colors.yellowAccent[100],),
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  onPressed: (productName.isEmpty ||
                      amount == 0)
                      ? null
                      : () async {
                    final authRepository = ref
                        .read(authRepositoryProvider);
                    final pressingRepository = ref.read(
                        pressingRepositoryProvider,);
                    final bonusAsyncValue = ref.read(
                        bonusValueProvider(
                            targetRatio,),); // changed watch to read
                    final userId =
                        authRepository.currentUserId;
                    final productName = ref
                        .read(selectedProductProvider)
                        .state;
                    final bonus = bonusAsyncValue *
                        ((workingHours - allowance) /
                            7.0);
                    final productRatioProvider =
                    ref.read(
                        targetRatioProvider(userId)
                            .notifier,);
                    final productRatio =
                    productRatioProvider
                        .getProductRatio(
                        productName.toLowerCase().trim(),);
// Retrieve the bonus value

                    try {
                      await pressingRepository.saveUserBonus(
                          userId,
                          productName,
                          bonus,
                          amount,
                          productRatio,
                          workingHours: (userState
                              .paidBreaks ??
                              false)
                              ? (userState
                              .realWorkingHours ??
                              0)
                              : (userState
                              .workingHours ??
                              0),);
if(mounted) {
                            ScaffoldMessenger.of(
                              buttonContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Saved to Wallet successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FormatException catch (e) {
                      if (e is String) {
                        await ref
                            .read(targetRatioProvider(
                            userId,)
                            .notifier,)
                            .init();
// Handle the case where the bonus is already added today
                            if (mounted){
                              ScaffoldMessenger.of(
                                buttonContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'This product has been overwritten because it was already added today.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
// Call editUserBonus if saveUserBonus fails
                        await pressingRepository
                            .editUserBonus(
                          e.message,
// Pass the bonusId as the first parameter
                          productName,
                          bonus,
                          amount,
                        );
                      } else {
if(mounted) {
                              ScaffoldMessenger.of(
                                buttonContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }

// Show a success message or navigate to another screen
                  },
                  child: const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
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
          ),),
    );
  }
  }
