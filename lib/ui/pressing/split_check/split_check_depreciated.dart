// import 'package:ballistics_wallet_flutter/custom_widgets/custom_text_field.dart';
// import 'package:ballistics_wallet_flutter/models/product_info.dart';
// import 'package:ballistics_wallet_flutter/providers/bonus_tables_provider.dart';
// import 'package:ballistics_wallet_flutter/providers/controllers.dart';
// import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
// import 'package:ballistics_wallet_flutter/providers/split_provider.dart';
// import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
// import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
// import 'package:ballistics_wallet_flutter/ui/pressing/split_check/colors.dart';
// import 'package:ballistics_wallet_flutter/utilities.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// class SplitCheck extends ConsumerStatefulWidget {
//   const SplitCheck({super.key});
//
//   @override
//   SplitCheckState createState() => SplitCheckState();
// }
//
// class SplitCheckState extends ConsumerState<SplitCheck> {
//   late TextEditingController targetController;
//   late TextEditingController amountPerBatchController;
//   late FocusNode focusNodeTarget;
//   late FocusNode focusNodeAmount;
//   late FocusNode focusNodeProductName;
//   bool shouldUpdateTargetController = true;
//   bool shouldUpdateAmountPerBatchController = true;
//   late double timePerBatch;
//   late int amountPerBatchSliderValue;
//   late int targetSlider;
//
//   @override
//   void initState() {
//     super.initState();
//     focusNodeTarget = FocusNode();
//     focusNodeAmount = FocusNode();
//     focusNodeProductName = FocusNode();
//     targetController = TextEditingController();
//     amountPerBatchController = TextEditingController();
//     targetController.text = '0'; // Initial required amount
//     amountPerBatchSliderValue =
//         int.tryParse(amountPerBatchController.text) ?? 1;
//     targetSlider = 1;
//
//     focusNodeTarget.addListener(() {});
//     focusNodeAmount.addListener(() {});
//     focusNodeProductName.addListener(() {});
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final initial = ref.read(focusedProductProvider).target.toString();
//       targetController.text = initial;
//       ref.read(requiredAmountProvider.notifier).state = int.parse(initial);
//     });
//     focusNodeTarget.addListener(() {
//       if (focusNodeTarget.hasFocus) {
//         // schedule after build
//         Future.microtask(() {
//           ref.read(requiredAmountProvider.notifier).state = 0;
//         });
//       }
//     });
//
//     // void onTargetChanged() {
//     //   // Implement logic if needed when target changes. For example, you might want to reset the flag here.
//     // }
//     //
//     // targetController.addListener(onTargetChanged);
//   }
//
//   @override
//   void dispose() {
//     focusNodeTarget.dispose();
//     focusNodeAmount.dispose();
//     targetController.dispose();
//     amountPerBatchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ref.watch(requiredAmountProvider);
//
//     final products = ref.watch(productInfoProvider); // Directly use the state
//     final productInfo = ref.watch(focusedProductProvider);
//     final hasProducts = productInfo.product.isNotEmpty;
//
//     final requiredAmount = double.tryParse(targetController.text) ?? 1;
//
//     if (shouldUpdateTargetController &&
//         targetController.text != productInfo.target.toString()) {
//       targetController.text = productInfo.target.toString();
//       shouldUpdateTargetController = false; // Reset the flag after updating
//     }
//
//     final amountPerBatchValue = ref.watch(amountPerBatchProvider);
//     if (shouldUpdateAmountPerBatchController &&
//         amountPerBatchController.text != amountPerBatchValue.toString()) {
//       amountPerBatchController.text = amountPerBatchValue.toString();
//       shouldUpdateAmountPerBatchController = false;
//     }
//
//     final amountPerBatch = int.tryParse(amountPerBatchController.text) ?? 1;
//     final batches = requiredAmount > 0 && amountPerBatch > 0
//         ? (requiredAmount / amountPerBatch).toInt()
//         : 1; // Safeguard against division by zero and ensure positive inputs
//
//     final extraBombs =
//         amountPerBatch != 0 ? (requiredAmount % amountPerBatch).toInt() : 0;
//
//     final productNameController =
//         ref.watch(productNameControllerProvider.notifier).controller;
//
//     final userState = ref.watch(userNotifierProvider);
//     final allowance = ref.watch(allowanceProvider);
//     final workingHours = userState.workingHours ?? 0.0;
//
//     final timePerBatch =
//         batches > 0 ? ((workingHours - 0.25) / batches * 60).toInt() : 1;
//
//     return Stack(
//       children: [
//         GestureDetector(
//           onTap: () {
//             FocusScope.of(context).unfocus();
//           },
//           child: Material(
//             color: Colors.transparent,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Column(
//                   children: [
//                     DecoratedBox(
//                       decoration: BoxDecoration(
//                         color: Colors.orange[100],
//                         borderRadius:
//                             const BorderRadius.all(Radius.circular(20)),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(4),
//                         child: DecoratedBox(
//                           decoration: BoxDecoration(
//                             color: Colors.orange[50],
//                             borderRadius:
//                                 const BorderRadius.all(Radius.circular(20)),
//                           ),
//                           child: Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.orange[50],
//                               borderRadius:
//                                   const BorderRadius.all(Radius.circular(33)),
//                             ),
//                             child: Column(
//                               children: [
//                                 Autocomplete<ProductInfo>(
//                                   optionsBuilder: (textEditingValue) {
//                                     if (textEditingValue.text.isEmpty) {
//                                       return const Iterable<
//                                           ProductInfo>.empty();
//                                     }
//                                     return products.where(
//                                       (productInfo) {
//                                         return productInfo.productName
//                                             .toLowerCase()
//                                             .contains(
//                                               textEditingValue.text
//                                                   .toLowerCase(),
//                                             );
//                                       },
//                                     );
//                                   },
//                                   displayStringForOption: (option) =>
//                                       option.productName,
//                                   fieldViewBuilder: (
//                                     context,
//                                     fieldTextEditingController,
//                                     focusNodeProductName,
//                                     onFieldSubmitted,
//                                   ) {
//                                     fieldTextEditingController.text =
//                                         productInfo.productName;
//
//                                     return CustomTextField(
//                                       controller: fieldTextEditingController,
//                                       focusNode: focusNodeProductName,
//                                       hintText: 'Add product name',
//                                       labelText: 'Product name',
//                                       onChanged: (value) {
//                                         // Optionally handle on change
//                                       },
//                                       onSubmitted: (value) {
//                                         onFieldSubmitted();
//                                       },
//                                       showClearIcon: true,
//                                     );
//                                   },
//                                   optionsViewBuilder: (
//                                     context,
//                                     onSelected,
//                                     options,
//                                   ) {
//                                     return Align(
//                                       alignment: Alignment.topLeft,
//                                       child: Padding(
//                                         padding: const EdgeInsets.fromLTRB(
//                                           0,
//                                           4,
//                                           0,
//                                           0,
//                                         ),
//                                         child: Material(
//                                           borderRadius: const BorderRadius.only(
//                                             topLeft: Radius.circular(33),
//                                             topRight: Radius.circular(33),
//                                             bottomRight: Radius.circular(20),
//                                             bottomLeft: Radius.circular(20),
//                                           ),
//                                           color: Colors.orange[100],
//                                           child: Container(
//                                             height: MediaQuery.of(context)
//                                                 .viewInsets
//                                                 .bottom,
//                                             width: MediaQuery.of(context)
//                                                     .size
//                                                     .width *
//                                                 0.9,
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   const BorderRadius.only(
//                                                 topLeft: Radius.circular(33),
//                                                 topRight: Radius.circular(33),
//                                                 bottomRight:
//                                                     Radius.circular(20),
//                                                 bottomLeft: Radius.circular(20),
//                                               ),
//                                               color: Colors.orange[100],
//                                             ),
//                                             child: Padding(
//                                               padding: const EdgeInsets.all(8),
//                                               child: ListView.builder(
//                                                 padding:
//                                                     const EdgeInsets.all(2),
//                                                 shrinkWrap: true,
//                                                 itemCount: options.length,
//                                                 itemBuilder: (context, index) {
//                                                   final option =
//                                                       options.elementAt(index);
//                                                   return GestureDetector(
//                                                     onTap: () =>
//                                                         onSelected(option),
//                                                     child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.all(
//                                                         4,
//                                                       ),
//                                                       child: DecoratedBox(
//                                                         decoration:
//                                                             BoxDecoration(
//                                                           borderRadius:
//                                                               const BorderRadius
//                                                                   .all(
//                                                             Radius.circular(
//                                                               33,
//                                                             ),
//                                                           ),
//                                                           color:
//                                                               Colors.orange[50],
//                                                         ),
//                                                         child: ListTile(
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                               33,
//                                                             ),
//                                                           ),
//                                                           title: Center(
//                                                             child: Text(
//                                                               option
//                                                                   .productName,
//                                                               style:
//                                                                   const TextStyle(
//                                                                 // Match style with main TextField
//                                                                 fontSize: 16,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           tileColor:
//                                                               Colors.white,
//                                                           selectedTileColor:
//                                                               Colors.grey[200],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   );
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   onSelected: (selection) async {
//                                     final productTarget = ((selection.target
//                                                 .toDouble()) *
//                                             ((workingHours - allowance) / 7.00))
//                                         .ceil();
//                                     ref.read(targetProvider.notifier).state =
//                                         productTarget;
//                                     productNameController.text =
//                                         selection.productName;
//                                     ref
//                                         .read(focusedProductProvider.notifier)
//                                         .state = selection;
//                                     await ref
//                                         .read(
//                                           lastSelectedProductProvider.notifier,
//                                         )
//                                         .saveSelectedProduct(
//                                           selection,
//                                         );
//                                     targetController.text =
//                                         selection.target.toString();
//                                     if (context.mounted) {
//                                       FocusScope.of(context).unfocus();
//                                     }
//                                   },
//                                 ),
//                                 const Divider(
//                                   height: 32,
//                                 ),
//                                 Autocomplete<BonusItem>(
//                                   optionsBuilder: (textEditingValue) {
//                                     // Always return the full bonus list
//                                     final bonusList = ref
//                                             .watch(bonusTableProvider)
//                                             .bonusData ??
//                                         [];
//                                     return bonusList;
//                                   },
//                                   displayStringForOption: (option) =>
//                                       option.requiredAmount.toString(),
//                                   fieldViewBuilder: (
//                                     context,
//                                     fieldTextEditingController,
//                                     focusNodeTarget,
//                                     onFieldSubmitted,
//                                   ) {
//                                     final requiredAmount =
//                                         ref.read(requiredAmountProvider);
//
//                                     fieldTextEditingController.text =
//                                         requiredAmount > 0
//                                             ? requiredAmount.toString()
//                                             : targetController.text;
//
//                                     return CustomTextField(
//                                       controller: fieldTextEditingController,
//                                       focusNode: focusNodeTarget,
//                                       hintText: 'Select target',
//                                       labelText: 'Target',
//                                       onChanged: (value) {
//                                         // Optionally handle on change
//                                       },
//                                       showClearIcon: true,
//                                     );
//                                   },
//                                   optionsViewBuilder: (
//                                     context,
//                                     onSelected,
//                                     options,
//                                   ) {
//                                     return Align(
//                                       alignment: Alignment.topLeft,
//                                       child: Padding(
//                                         padding: const EdgeInsets.fromLTRB(
//                                           0,
//                                           4,
//                                           0,
//                                           0,
//                                         ),
//                                         child: Material(
//                                           borderRadius: const BorderRadius.only(
//                                             topLeft: Radius.circular(33),
//                                             topRight: Radius.circular(33),
//                                             bottomRight: Radius.circular(20),
//                                             bottomLeft: Radius.circular(20),
//                                           ),
//                                           color: Colors.orange[100],
//                                           child: Container(
//                                             height: MediaQuery.of(context)
//                                                 .viewInsets
//                                                 .bottom,
//                                             width: MediaQuery.of(context)
//                                                     .size
//                                                     .width *
//                                                 0.9,
//                                             decoration: BoxDecoration(
//                                               borderRadius:
//                                                   const BorderRadius.only(
//                                                 topLeft: Radius.circular(33),
//                                                 topRight: Radius.circular(33),
//                                                 bottomRight:
//                                                     Radius.circular(20),
//                                                 bottomLeft: Radius.circular(20),
//                                               ),
//                                               color: Colors.orange[100],
//                                             ),
//                                             child: Padding(
//                                               padding: const EdgeInsets.all(8),
//                                               child: ListView.builder(
//                                                 padding:
//                                                     const EdgeInsets.all(2),
//                                                 shrinkWrap: true,
//                                                 itemCount: options.length,
//                                                 itemBuilder: (context, index) {
//                                                   final option =
//                                                       options.elementAt(index);
//                                                   return GestureDetector(
//                                                     onTap: () =>
//                                                         onSelected(option),
//                                                     child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.all(
//                                                         4,
//                                                       ),
//                                                       child: DecoratedBox(
//                                                         decoration:
//                                                             BoxDecoration(
//                                                           borderRadius:
//                                                               const BorderRadius
//                                                                   .all(
//                                                             Radius.circular(
//                                                               33,
//                                                             ),
//                                                           ),
//                                                           color:
//                                                               Colors.orange[50],
//                                                         ),
//                                                         child: ListTile(
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                               33,
//                                                             ),
//                                                           ),
//                                                           title: Center(
//                                                             child: Text(
//                                                               option
//                                                                   .requiredAmount
//                                                                   .toString(),
//                                                               style:
//                                                                   const TextStyle(
//                                                                 // Match style with main TextField
//                                                                 fontSize: 16,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .bold,
//                                                                 color: Colors
//                                                                     .black,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           subtitle: Center(
//                                                             child: Text(
//                                                               '£${formatDouble(option.bonus)}',
//                                                             ),
//                                                           ),
//                                                           tileColor:
//                                                               Colors.white,
//                                                           selectedTileColor:
//                                                               Colors.grey[200],
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   );
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                   onSelected: (selection) async {
//                                     targetController.text =
//                                         selection.requiredAmount.toString();
//                                     ref
//                                         .read(requiredAmountProvider.notifier)
//                                         .state = selection.requiredAmount;
//                                     focusNodeTarget.unfocus();
//                                     focusNodeProductName
//                                         .unfocus(); // Unfocus using the locally stored focusNode
//                                     FocusScope.of(context).unfocus();
//                                   },
//                                 ),
//                                 const Divider(
//                                   height: 32,
//                                 ),
//                                 SizedBox(
//                                   width:
//                                       MediaQuery.of(context).size.width * 0.40,
//                                   child: CustomTextField(
//                                     focusNode: focusNodeAmount,
//                                     controller: amountPerBatchController,
//                                     hintText: 'Enter amount',
//                                     labelText: 'Amount per batch',
//                                     keyboardType: TextInputType.number,
//                                     showClearIcon: true,
//                                   ),
//                                 ),
//                                 Slider(
//                                   value: amountPerBatchSliderValue
//                                       .toDouble(), // Convert int to double for Slider
//                                   min: 1,
//                                   max:
//                                       150, // Define the maximum amount per batch as an integer
//                                   divisions:
//                                       149, // This will create steps for each integer value between min and max
//                                   label: amountPerBatchSliderValue.toString(),
//                                   onChanged: int.tryParse(
//                                             targetController.text,
//                                           ) !=
//                                           null
//                                       ? (value) {
//                                           setState(() {
//                                             amountPerBatchSliderValue = value
//                                                 .round(); // Convert back to int and store
//                                             amountPerBatchController.text =
//                                                 amountPerBatchSliderValue
//                                                     .toString(); // Update text controller
//                                           });
//                                         }
//                                       : null, // Disable onChanged if requiredAmount is 0 or less
//                                 ),
//                                 const Divider(
//                                   height: 32,
//                                 ),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Container(
//                                       padding: const EdgeInsets.all(2),
//                                       decoration: BoxDecoration(
//                                         color: Colors.orange[100],
//                                         borderRadius: BorderRadius.circular(20),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 Colors.orange.withOpacity(0.5),
//                                             offset: const Offset(-2, 2.5),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(4),
//                                         child: Row(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Text(
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                               'Batches: $batches',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Container(
//                                       padding: const EdgeInsets.all(4),
//                                       decoration: BoxDecoration(
//                                         color: Colors.orange[100],
//                                         borderRadius: BorderRadius.circular(20),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 Colors.orange.withOpacity(0.5),
//                                             offset: const Offset(-2, 2.5),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(4),
//                                         child: Row(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Text(
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                               'Extra items: $extraBombs',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                     Container(
//                                       padding: const EdgeInsets.all(4),
//                                       decoration: BoxDecoration(
//                                         color: Colors.orange[100],
//                                         borderRadius: BorderRadius.circular(20),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 Colors.orange.withOpacity(0.5),
//                                             offset: const Offset(-2, 2.5),
//                                           ),
//                                         ],
//                                       ),
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(4),
//                                         child: Row(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Text(
//                                               style: const TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                               '$timePerBatch min / batch',
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(
//                                   height: 8,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     ListView.builder(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 8,
//                       ), // Add vertical padding
//                       physics: const ClampingScrollPhysics(),
//                       shrinkWrap: true,
//                       itemCount: hasProducts ? productInfo.product.length : 0,
//                       itemBuilder: (context, index) {
//                         final product = productInfo;
//                         final systemG =
//                             ((product.product[index].systemG * amountPerBatch) /
//                                     1000)
//                                 .toStringAsFixed(2);
//                         final citricG = ((product.product[index].systemCitric *
//                                     amountPerBatch) /
//                                 1000)
//                             .toStringAsFixed(2);
//
//                         String extractColorName(String colorString) {
//                           if (colorString.contains('-')) {
//                             return colorString.split('-').last.trim();
//                           } else {
//                             final words = colorString.split(' ');
//                             if (words.length > 1) {
//                               final colorName = words.last.trim();
//                               if (isValidColor(colorName)) {
//                                 return colorName;
//                               } else {
//                                 return words.first.trim();
//                               }
//                             } else {
//                               return words.first.trim();
//                             }
//                           }
//                         }
//
//                         String extractColorNameForUser(String colorString) {
//                           if (colorString.contains('-')) {
//                             return colorString.split('-').last.trim();
//                           } else {
//                             return colorString;
//                           }
//                         }
//
//                         final color = getColorFromString(
//                           extractColorName(product.product[index].productColor),
//                         );
//                         return Padding(
//                           padding: const EdgeInsets.all(4),
//                           child: Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: color,
//                               borderRadius: BorderRadius.circular(33),
//                             ),
//                             child: Container(
//                               padding: const EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: getColorFromString(
//                                   extractColorName(
//                                     product.product[index].productColor,
//                                   ),
//                                   accent: true,
//                                 ),
//                                 borderRadius: BorderRadius.circular(25),
//                               ),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   SizedBox(
//                                     width:
//                                         MediaQuery.sizeOf(context).width * 0.25,
//                                     child: Center(
//                                       child: Text(
//                                         extractColorNameForUser(
//                                           product.product[index].productColor,
//                                         ),
//                                         style: const TextStyle(fontSize: 20),
//                                       ),
//                                     ),
//                                   ),
//                                   Column(
//                                     children: [
//                                       Text(
//                                         'Powder: $systemG kg',
//                                         style: const TextStyle(fontSize: 20),
//                                       ),
//                                       Text(
//                                         'Citric: $citricG kg',
//                                         style: const TextStyle(
//                                           fontSize: 20,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
