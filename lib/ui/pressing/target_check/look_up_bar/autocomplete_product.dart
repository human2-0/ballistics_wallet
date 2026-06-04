// Widgets in this file are app screens, not package API.
// ignore_for_file: public_member_api_docs

import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/add_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/delete_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/edit_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsListSuggested extends ConsumerStatefulWidget {
  const ProductsListSuggested({super.key});

  @override
  ProductsListSuggestedState createState() => ProductsListSuggestedState();
}

class ProductsListSuggestedState extends ConsumerState<ProductsListSuggested> {
  @override
  Widget build(BuildContext context) {
    final products = ref.watch(
      productInfoProvider,
    ); // Assuming this now returns a List directly

    final controller = ref.watch(productNameControllerProvider);
    final query = controller.toLowerCase().trim();
    final userState = ref.watch(userNotifierProvider);
    final allowance = ref.watch(allowanceProvider);
    final workingHours = userState.workingHours ?? 0.0;
    final effortFilter = ref.watch(productEffortFilterProvider);
    final filteredProducts =
        products
            .where(
              (product) =>
                  product.productName.toLowerCase().trim().contains(query),
            )
            .toList()
          ..sort(
            (left, right) => _compareByEffort(
              left,
              right,
              effortFilter: effortFilter,
              workingHours: workingHours,
              allowance: allowance,
            ),
          );
    final focusNode = ref.watch(focusNodeProvider);

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(33)),
          color: Colors.orange[50],
        ),
        child:
            filteredProducts.isEmpty
                ? const AddProductDialog()
                : NotificationListener(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollStartNotification) {
                      focusNode.unfocus();
                    }
                    return true;
                  },
                  child: ListView.builder(
                    itemCount: filteredProducts.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredProducts.length) {
                        // Show AddProductDialog as the last item
                        return const AddProductDialog();
                      } else {
                        final product = filteredProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(33),
                            child: ListTile(
                              trailing: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    color: Colors.red,
                                  ),
                                  Text('Hold to edit'),
                                ],
                              ),
                              title: Text(product.productName),
                              subtitle: Text(
                                _productSubtitle(
                                  product,
                                  workingHours: workingHours,
                                  allowance: allowance,
                                ),
                              ),
                              onTap: () async {
                                ref
                                    .read(focusedProductProvider.notifier)
                                    .state = product;

                                ref
                                    .read(
                                      productNameControllerProvider.notifier,
                                    )
                                    .controller
                                    .text = product.productName;
                                ref.read(targetProvider.notifier).state =
                                    product.target;

                                // Save the selected product history
                                await ref
                                    .read(lastSelectedProductProvider.notifier)
                                    .saveSelectedProduct(product);
                                ref.read(showListProvider.notifier).state =
                                    false;
                                ref.read(focusNodeProvider).unfocus();
                              },
                              onLongPress: () async {
                                // Show the bottom sheet with options
                                final action = await showModalBottomSheet<
                                  String
                                >(
                                  context: context,
                                  builder:
                                      (context) => Wrap(
                                        children: [
                                          ListTile(
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(
                                                  33,
                                                ), // Rounded top left corner
                                                topRight: Radius.circular(
                                                  33,
                                                ), // Rounded top right corner
                                              ),
                                            ),
                                            tileColor: Colors.red[100],
                                            iconColor: Colors.red,
                                            leading: const Icon(Icons.delete),
                                            title: const Text('Delete'),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'delete',
                                                ),
                                          ),
                                          ListTile(
                                            tileColor: Colors.yellow[100],
                                            iconColor: Colors.yellow[700],
                                            leading: const Icon(Icons.edit),
                                            title: const Text('Edit'),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'edit',
                                                ),
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.cancel),
                                            title: const Text('Cancel'),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'cancel',
                                                ),
                                          ),
                                        ],
                                      ),
                                );

                                // Handle the selected action
                                switch (action) {
                                  case 'delete':
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          timeStamp,
                                        ) async {
                                          await showDialog<bool>(
                                            context: context,
                                            builder:
                                                (context) => DeleteItem(
                                                  productName:
                                                      product.productName,
                                                ),
                                          );
                                        });

                                  case 'edit':
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((
                                          timeStamp,
                                        ) async {
                                          await showEditProductDialog(
                                            context,
                                            ref,
                                            product: product,
                                          );
                                        });
                                  case 'cancel':
                                  default:
                                    // Do nothing for cancel or undefined actions
                                    break;
                                }
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
      ),
    );
  }
}

int _compareByEffort(
  ProductInfo left,
  ProductInfo right, {
  required ProductEffortFilter effortFilter,
  required double workingHours,
  required double allowance,
}) {
  if (effortFilter == ProductEffortFilter.none) {
    return left.productName.compareTo(right.productName);
  }

  final leftKg = _minimumTargetKg(
    left,
    workingHours: workingHours,
    allowance: allowance,
  );
  final rightKg = _minimumTargetKg(
    right,
    workingHours: workingHours,
    allowance: allowance,
  );

  final leftHasWeight = leftKg > 0;
  final rightHasWeight = rightKg > 0;
  if (leftHasWeight != rightHasWeight) {
    return leftHasWeight ? -1 : 1;
  }

  final effortCompare =
      effortFilter == ProductEffortFilter.leastEffort
          ? leftKg.compareTo(rightKg)
          : rightKg.compareTo(leftKg);
  if (effortCompare != 0) return effortCompare;
  return left.productName.compareTo(right.productName);
}

String _productSubtitle(
  ProductInfo product, {
  required double workingHours,
  required double allowance,
}) {
  final target = _minimumTarget(product, workingHours, allowance);
  final kilograms = _minimumTargetKg(
    product,
    workingHours: workingHours,
    allowance: allowance,
  );
  if (kilograms <= 0) return 'Target: $target';
  return 'Target: $target • ${kilograms.toStringAsFixed(2)} kg';
}

int _minimumTarget(ProductInfo product, double workingHours, double allowance) {
  final effectiveHours = workingHours - allowance;
  if (effectiveHours <= 0) return 0;
  return (product.target * (effectiveHours / 7)).ceil();
}

double _minimumTargetKg(
  ProductInfo product, {
  required double workingHours,
  required double allowance,
}) {
  if (!product.hasWeightFormula) return 0;
  return _minimumTarget(product, workingHours, allowance) *
      product.finalProductWeightGrams /
      1000;
}
