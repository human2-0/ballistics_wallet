import 'package:ballistics_wallet_flutter/models/product_name.dart';
import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/providers/wallet_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddBonusListItem extends HookConsumerWidget {

  const AddBonusListItem({required this.onAdd, required this.selectedDate, required this.userId, super.key,
  });
  final void Function(Map<String, dynamic>) onAdd;

  final DateTime selectedDate;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newBonusAmountController = ref.watch(bonusAmountControllerProvider);
    final newProductNameController = ref.watch(productNameControllerProvider);
    final overtimeHoursController = ref.watch(overtimeHoursControllerProvider);
    final newProductAmountController =
    ref.watch(productAmountControllerProvider);
    final amountFocusNode = useFocusNode();
    final bonusAmountFocusNode = FocusNode();


    final userBonusNotifier = ref.watch(userBonusNotifierProvider.notifier);

    final isOvertime = useState(false);

    return Padding(
      padding: const EdgeInsets.all(30),
      child: TextButton(
        onPressed: () async {
          await showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (context) => StatefulBuilder(
                  builder: (context, setState) => GestureDetector(
                      onTap: (){
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery
                              .of(context)
                              .viewInsets
                              .bottom,
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
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(RegExp('[0-9]+[,.]{0,1}[0-9]*')),
                                    TextInputFormatter.withFunction(
                                          (oldValue, newValue) => newValue.copyWith(
                                        text: newValue.text.replaceAll(',', '.'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<List<ProductName>>(
                                future: ref
                                    .watch(pressingRepositoryProvider)
                                    .readProductsPressing(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final productList = snapshot.data!
                                        .map((product) =>
                                        product.name)
                                        .toList();
                                    return DecoratedBox(
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
                                          controller: newProductNameController,
                                          decoration: InputDecoration(
                                            alignLabelWithHint: true,
                                            hintText: 'Product Name',
                                            filled: true,
                                            fillColor: Colors.orange[100],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(
                                                  33),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        suggestionsCallback: (pattern) => productList
                                              .where((product) =>
                                              product
                                                  .toLowerCase()
                                                  .contains(pattern.toLowerCase()))
                                              .toList(),
                                        itemBuilder: (context, suggestion) => ListTile(
                                            title: Text(suggestion),
                                          ),
                                        onSuggestionSelected: (suggestion) {
                                          newProductNameController.text =
                                              suggestion;
                                        },
                                        noItemsFoundBuilder: (context) =>
                                        const Text('No matches found'),
                                      ),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  // Show a loading indicator while waiting for the products
                                  return const CircularProgressIndicator();
                                },
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
                                  child: TextField(controller: overtimeHoursController,
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
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                    MaterialStateProperty.all(Colors.tealAccent),
                                    shadowColor:
                                    MaterialStateProperty.all(Colors.tealAccent),
                                    elevation: MaterialStateProperty.all(
                                        10), // adjust for desired shadow effect
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                  focusNode: amountFocusNode,
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();

                                    final bonusAmount =
                                    double.tryParse(newBonusAmountController.text);
                                    final productName = newProductNameController
                                        .text;
                                    final productAmount =
                                    int.tryParse(newProductAmountController.text);
                                    final workingHours = isOvertime.value
                                        ? double.tryParse(overtimeHoursController.text)
                                        : ref
                                        .read(userNotifierProvider)
                                        .realWorkingHours;




                                    if ((bonusAmount != null) ||
                                        (productName.isNotEmpty &&
                                            productAmount != null)) {
                                      // Clear the TextFields here before initiating the async operations.

                                      // Use `await` instead of `then` to ensure that the next operation doesn't start until this one is done.
                                      await userBonusNotifier.saveUserBonusCalendar(
                                        userId,
                                        productName,
                                        bonusAmount ?? 0,
                                        productAmount ?? 0,
                                        selectedDate,
                                        workingHours!,
                                        isOvertime: isOvertime.value,
                                      );

                                      // This code will only run after saveUserBonusCalendar() has finished.

                                      newBonusAmountController.clear();
                                      newProductNameController.clear();
                                      newProductAmountController.clear();
                                      overtimeHoursController.clear();


                                      // Close the sheet after all operations are done.
                                      Navigator.of(context).pop();
                                      await ref.read(targetRatioProvider(userId).notifier).init();

                                    } else {
                                      // Close the sheet if the data validation fails.
                                      Navigator.of(context).pop();
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
                    )),
          );
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
                offset: const Offset(5, 10), // Increase the offset for a deeper look
                blurRadius: 27, // Increase the blur radius for a softer shadow
                spreadRadius: 4, // Increase the spread radius for a more intense shadow
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
