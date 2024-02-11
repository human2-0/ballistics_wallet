import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/add_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/delete_item.dart';
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
        productInfoProvider,); // Assuming this now returns a List directly
    final searchTerm = ref.watch(searchTermProvider).toLowerCase();
    final filteredProducts = products
        .where(
            (product) => product.productName.toLowerCase().contains(searchTerm),)
        .toList();

    final userState = ref.watch(userNotifierProvider);
    final allowance = ref.watch(allowanceProvider);
    final workingHours = userState.workingHours ?? 0.0;

    final textEditingController = ref.watch(textEditingControllerProvider);

    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(33),
          ),
          color: Colors.orange[50],
        ),
        child: filteredProducts.isEmpty
            ? const AddProductDialog() // Show add product dialog if no products match the search term
            : ListView.builder(
                itemCount:
                    filteredProducts.isEmpty ? 1 : filteredProducts.length,
                itemBuilder: (context, index) {
                  if (filteredProducts.isEmpty) {
                    return const AddProductDialog();
                  }
// If the index is not 0, adjust it by 1 to get the correct product
                  else {
                    final product = filteredProducts[index];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(33),
                        color: Colors.white,
                      ),
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 10,),
                      child: ListTile(
                        trailing: const Icon(
                          Icons.touch_app_outlined,
                          color: Colors.red,
                        ),
                        title: Text(product.productName),
                        subtitle: Text(
                          'Target: ${((product.target.toDouble()) * ((workingHours - allowance) / 7.00)).ceil()}',
                        ),
                        onTap: () async {
                          final selectedProductName = product.productName;
                          final productTarget = ((product.target.toDouble()) *
                                  ((workingHours - allowance) / 7.00))
                              .ceil();


                          // Check if the widget is still mounted before proceeding
                          if (!mounted) return;

                          // Update the state
                          ref
                              .read(selectedProductProvider.notifier)
                              .state
                              .state = selectedProductName;
                          textEditingController.text =
                              selectedProductName; // Update the controller's text
                          ref.read(showListProvider.notifier).state = false;
                          ref.read(focusNodeProvider).unfocus();

                          // Update the targetProvider state
                          await ref
                              .read(targetProvider.notifier)
                              .updateTarget(productTarget);

                          // Save the selected product history
                          await ref
                              .read(lastSelectedProductProvider.notifier)
                              .saveSelectedProduct(
                                SelectedProduct(
                                  name: product.productName,
                                  selectedDate: DateTime.now(),
                                  target: productTarget,
                                ),
                              );
                          if (mounted) {
                            ref.read(focusedProductProvider.notifier).state =
                                product;
                          }
                        },
                        onLongPress: () async {
                          // Show the DeleteItem dialog
                          await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                DeleteItem(productName: product.productName),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}
