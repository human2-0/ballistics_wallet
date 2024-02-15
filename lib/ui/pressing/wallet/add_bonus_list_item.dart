import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/repository/pressing_db_repository.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddBonusListItem extends StatefulHookConsumerWidget {
  const AddBonusListItem({
    required this.onAdd,
    required this.selectedDate,
    required this.userId,
    super.key,
  });

  final void Function(Map<String, dynamic>) onAdd;

  final DateTime selectedDate;
  final String userId;

  @override
  AddBonusListItemState createState() => AddBonusListItemState();
}

class AddBonusListItemState extends ConsumerState<AddBonusListItem> {
  @override
  Widget build(BuildContext context) {
    final newBonusAmountController = ref.watch(bonusAmountControllerProvider);
    final newProductNameController = ref.watch(walletProductNameControllerProvider);
    final overtimeHoursController = ref.watch(overtimeHoursControllerProvider);
    final newProductAmountController =
        ref.watch(productAmountControllerProvider);
    // final amountFocusNode = useFocusNode();
    final bonusAmountFocusNode = FocusNode();

    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);

    final isOvertime = useState(false);

    Future<void> showAddBottomModalSheet(
        BuildContext context, PressingRepository pressingRepository,) async {
      final productList = ref.watch(productInfoProvider);
      await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Add Bonus',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(33),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(1),
                            offset: const Offset(2, -2.5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          newBonusAmountController.text = value;
                        },
                        focusNode: bonusAmountFocusNode,
                        controller: newBonusAmountController,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: 'Bonus',
                          filled: true,
                          fillColor: Colors.orange[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(33),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp('[0-9]+[,.]{0,1}[0-9]*'),),
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.replaceAll(',', '.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(33),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(1),
                          offset: const Offset(2, -2.5),
                        ),
                      ],
                    ),
                    child: TypeAheadFormField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        onChanged: (value) {
                          newProductNameController.text = value;
                        },
                        controller: newProductNameController,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: 'Product Name',
                          filled: true,
                          fillColor: Colors.orange[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              33,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      suggestionsCallback: (pattern) {
                        return productList
                            .map((product) => product.productName)
                            .where((productName) => productName.toLowerCase().contains(pattern.toLowerCase()))
                            .toList();
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion),
                        );
                      },
                      onSuggestionSelected: (suggestion) {
                        newProductNameController.text = suggestion;
                      },
                      noItemsFoundBuilder: (context) => const Text('No matches found'),
                    ),
                  ),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(33),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(1),
                            offset: const Offset(2, -2.5),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          newProductAmountController.text = value;
                        },
                        controller: newProductAmountController,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: 'Amount',
                          filled: true,
                          fillColor: Colors.orange[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(33),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SwitchListTile(
                        title: const Text('Overtime'),
                        value: isOvertime.value,
                        onChanged: (value) {
                          setState(() {
                            isOvertime.value = value;
                          });
                        },
                        secondary: const Icon(Icons.access_time),
                      ),
                    ),
                    if (isOvertime.value)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(1),
                              offset: const Offset(2, -2.5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: overtimeHoursController,
                          decoration: InputDecoration(
                            alignLabelWithHint: true,
                            hintText: 'Overtime hours',
                            filled: true,
                            fillColor: Colors.orange[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(33),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child:
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.tealAccent),
                          shadowColor:
                              MaterialStateProperty.all(Colors.tealAccent),
                          elevation: MaterialStateProperty.all(
                            10,
                          ), // adjust for desired shadow effect
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final bonusAmount =
                              double.tryParse(newBonusAmountController.text);
                          final productName = newProductNameController.text;
                          final productAmount =
                              int.tryParse(newProductAmountController.text);
                          final workingHours = isOvertime.value
                              ? double.tryParse(overtimeHoursController.text)
                              : ref.read(userNotifierProvider).realWorkingHours;

                          if ((bonusAmount != null) ||
                              (productName.isNotEmpty &&
                                  productAmount != null)) {
                            // Clear the TextFields here before initiating the async operations.

                            // Use `await` instead of `then` to ensure that the next operation doesn't start until this one is done.
                            await userBonusNotifier.saveUserBonusCalendar(
                              widget.userId,
                              productName,
                              bonusAmount ?? 0,
                              productAmount ?? 0,
                              widget.selectedDate,
                              workingHours!,
                              isOvertime: isOvertime.value,
                            );

                            // This code will only run after saveUserBonusCalendar() has finished.

                            newBonusAmountController.clear();
                            newProductNameController.clear();
                            newProductAmountController.clear();
                            overtimeHoursController.clear();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                            await ref
                                .read(
                              targetRatioProvider(widget.userId).notifier,)
                                .init();
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.brown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: TextButton(
        onPressed: () async {
          final pressingRepository = ref.watch(pressingRepositoryProvider);
          await showAddBottomModalSheet(context, pressingRepository);
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber,
                Colors.orange,
              ],
              stops: [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.lightBlueAccent.withOpacity(0.7),
                offset: const Offset(
                    5, 10,), // Increase the offset for a deeper look
                blurRadius: 27, // Increase the blur radius for a softer shadow
                spreadRadius:
                    4, // Increase the spread radius for a more intense shadow
              ),
            ],
            borderRadius: const BorderRadius.all(
              Radius.circular(18),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.brown,
            ),
          ),
        ),
      ),
    );
  }
}

enum OperationState {
  idle,
  processing,
  completed,
}
