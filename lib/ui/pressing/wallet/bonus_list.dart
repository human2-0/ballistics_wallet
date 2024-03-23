import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BonusListItem extends StatefulHookConsumerWidget {
  const BonusListItem({
    required this.date,
    required this.index,
    required this.event,
    required this.userId,
    required this.parentIndex,
    super.key,
    this.onDelete,
  });
  final DateTime date;
  final int index;
  final Map<String, dynamic> event;
  final String userId;
  final Function? onDelete;
  final int parentIndex;

  @override
  BonusListItemState createState() => BonusListItemState();
}

class BonusListItemState extends ConsumerState<BonusListItem> {
  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final onDelete = widget.onDelete;
    final index = widget.index;
    final userId = widget.userId;
    final parentIndex = widget.parentIndex;
    final date = widget.date;
    final newProductNameController = useTextEditingController();
    final newProductAmountController = useTextEditingController();

    // Ensure that produced is not null
    final produced = event.getList('produced');

    final isEditing = useState(false);
    final newBonusAmountController =
        useTextEditingController(text: '${event['bonus']}');
    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);

    final primaryColor =
        (event['isOvertime'] != null && event['isOvertime'] as bool)
            ? Colors.blue
            : Colors.orange;

    final productList = ref
        .watch(productInfoProvider)
        .map((product) => product.productName)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(33)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.1, 0.5, 0.7, 0.9],
            colors: [
              primaryColor[50]!.withOpacity(0.5),
              primaryColor[100]!,
              primaryColor[200]!,
              primaryColor[300]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor[500]!.withOpacity(0.6),
              offset: const Offset(10, 10),
              blurRadius: 10,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              offset: const Offset(-5, -5),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Add this line to center the row
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(33),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor[500]!.withOpacity(0.6),
                            offset: const Offset(10, 10),
                            blurRadius: 10,
                            spreadRadius: -5,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.4),
                            offset: const Offset(-5, -5),
                            blurRadius: 15,
                            spreadRadius: -5,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: const [0.1, 0.5, 0.7, 0.9],
                          colors: [
                            primaryColor.withOpacity(0.4),
                            primaryColor[300]!,
                            primaryColor.withOpacity(0.5),
                            primaryColor.withOpacity(0.01),
                          ],
                        ),
                        color: Colors.white,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.17,
                        height: MediaQuery.of(context).size.height * 0.09,
                        child: Center(
                          child: Text(
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            'Hours\n    ${formatDouble(event.getDouble('workingHours'))}',
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      isEditing.value = !isEditing.value; // toggle editing mode
                      if (isEditing.value) {
                        newBonusAmountController.text =
                            formatDouble(event.getDouble('workingHours'));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor[500]!.withOpacity(0.6),
                              offset: const Offset(10, 10),
                              blurRadius: 10,
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              offset: const Offset(-5, -5),
                              blurRadius: 15,
                              spreadRadius: -5,
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.1, 0.5, 0.7, 0.9],
                            colors: [
                              primaryColor.withOpacity(0.4),
                              primaryColor[300]!,
                              primaryColor.withOpacity(0.5),
                              primaryColor.withOpacity(0.01),
                            ],
                          ),
                          color: Colors.white,
                        ),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25,
                          height: MediaQuery.of(context).size.height * 0.09,
                          child: Stack(
                            children: [
                              Center(
                                child: isEditing.value
                                    ? TextField(
                                        controller: newBonusAmountController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        '£${formatDouble(event.getDouble('bonus'))}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              if (isEditing.value) ...[
                                Positioned(
                                  left: -10,
                                  top: -10,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      await ref
                                          .read(
                                            userBonusNotifierProvider.notifier,
                                          )
                                          .deleteUserBonus(
                                              event['id'].toString(), userId,)
                                          .then((_) {
                                        event['bonus'] = 0;
                                        isEditing.value = false;
                                        newBonusAmountController.clear();

                                        // Only call init() after the delete operation has completed.
                                        ref
                                            .read(
                                              targetRatioProvider(userId)
                                                  .notifier,
                                            )
                                            .init();
                                      });
                                    },
                                  ),
                                ),
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: IconButton(
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    onPressed: () async {
                                      final newBonusAmount = double.tryParse(
                                        newBonusAmountController.text,
                                      );
                                      if (newBonusAmount != null) {
                                        await ref
                                            .read(
                                              userBonusNotifierProvider
                                                  .notifier,
                                            )
                                            .editBonus(
                                              userId,
                                              event['id'].toString(),
                                              newBonusAmount,
                                            );
                                        event['bonus'] = newBonusAmount;
                                        isEditing.value = false;
                                        newBonusAmountController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: produced.length,
                          itemBuilder: (context, i) {
                            final item = produced[i];
                            return ListTile(
                              title: Text(item['productName'].toString()),
                              subtitle: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Amount: ${item['amount']}'),
                                ],
                              ),
                              trailing: IconButton(
                                color: Colors.red,
                                icon: Icon(
                                  color: Colors.pink[50],
                                  Icons.delete_outline,
                                ),
                                onPressed: () async {
                                  onDelete?.call(parentIndex, index);
                                  await ref
                                      .read(
                                        targetRatioProvider(userId).notifier,
                                      )
                                      .init();
                                },
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 115, 0),
                          child: TextButton(
                            onPressed: () async {
                              await showModalBottomSheet<Widget>(
                                isScrollControlled: true,
                                context: context,
                                builder: (context) => AnimatedPadding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                  ),
                                  duration: const Duration(milliseconds: 100),
                                  child: SingleChildScrollView(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Text(
                                            'Add Product',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(33),),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange
                                                      .withOpacity(1),
                                                  offset: const Offset(2, -2.5),
                                                ),
                                              ],
                                            ),
                                            child: TypeAheadField(
                                              textFieldConfiguration:
                                                  TextFieldConfiguration(
                                                controller:
                                                    newProductNameController,
                                                decoration: InputDecoration(
                                                  alignLabelWithHint: true,
                                                  hintText: 'Product Name',
                                                  filled: true,
                                                  fillColor: Colors.orange[100],
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            33,),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              suggestionsCallback: (pattern) =>
                                                  productList
                                                      .where((product) => product
                                                          .toLowerCase()
                                                          .contains(pattern
                                                              .toLowerCase(),),)
                                                      .toList(),
                                              itemBuilder:
                                                  (context, suggestion) {
                                                // The suggestion parameter needs to be explicitly cast to String
                                                final suggestionStr =
                                                    suggestion;
                                                return ListTile(
                                                    title: Text(suggestionStr),);
                                              },
                                              onSuggestionSelected:
                                                  (suggestion) {
                                                // The suggestion parameter needs to be explicitly cast to String
                                                final suggestionStr =
                                                    suggestion;
                                                newProductNameController.text =
                                                    suggestionStr;
                                              },
                                              noItemsFoundBuilder: (context) =>
                                                  const Text(
                                                      'No matches found',),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.all(
                                                Radius.circular(33),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange
                                                      .withOpacity(1),
                                                  offset: const Offset(2, -2.5),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller:
                                                  newProductAmountController,
                                              decoration: InputDecoration(
                                                alignLabelWithHint: true,
                                                hintText: 'Amount',
                                                filled: true,
                                                fillColor: Colors.orange[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(33),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const SizedBox(height: 16),
                                          Center(
                                            child: ElevatedButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all(
                                                  Colors.tealAccent,
                                                ),
                                                shadowColor:
                                                    MaterialStateProperty.all(
                                                  Colors.tealAccent,
                                                ),
                                                elevation:
                                                    MaterialStateProperty.all(
                                                  10,
                                                ), // adjust for desired shadow effect
                                                shape:
                                                    MaterialStateProperty.all<
                                                        RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              onPressed: () async {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                ref
                                                  ..read(
                                                    userBonusNotifierProvider
                                                        .notifier,
                                                  )
                                                  ..read(
                                                    targetRatioProvider(userId)
                                                        .notifier,
                                                  );
                                                final newProductName =
                                                    newProductNameController
                                                        .text;
                                                final newProductAmount =
                                                    int.tryParse(
                                                  newProductAmountController
                                                      .text,
                                                );

                                                final workingHours = ref
                                                    .read(userNotifierProvider)
                                                    .workingHours;

                                                if (newProductName.isNotEmpty &&
                                                    newProductAmount != null) {
                                                  await userBonusNotifier
                                                      .saveUserBonusCalendar(
                                                    userId,
                                                    newProductName, // if null, set to 0
                                                    0,
                                                    newProductAmount,
                                                    date,
                                                    workingHours!,
                                                  );
                                                  await ref
                                                      .read(
                                                        targetRatioProvider(
                                                          userId,
                                                        ).notifier,
                                                      )
                                                      .init();
                                                  newProductNameController
                                                      .clear();
                                                  newProductAmountController
                                                      .clear();
                                                  if (mounted) {
                                                    Navigator.of(context).pop();
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please provide more data',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                style: TextStyle(
                                                  color: Colors.brown,
                                                ),
                                                'Save',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor[100]!,
                                    primaryColor[200]!,
                                  ],
                                  stops: const [0.0, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.6),
                                    offset: const Offset(7, 9),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4),
                                    offset: const Offset(-2, -4),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                  ),
                                ],
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
