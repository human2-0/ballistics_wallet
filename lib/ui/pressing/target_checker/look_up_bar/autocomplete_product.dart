import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/add_product.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/delete_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class ProductsListSuggested extends ConsumerStatefulWidget {
  const ProductsListSuggested({super.key});

  @override
  ProductsListSuggestedState createState() => ProductsListSuggestedState();
}

class ProductsListSuggestedState extends ConsumerState<ProductsListSuggested> {
  @override
  Widget build(BuildContext context) {
    final updated = ref.watch(productUpdateProvider);
    final repo = ref.read(lastSelectedProductProvider.notifier);
    final products = ref.watch(productsProvider(updated));

    final userState = ref.watch(userNotifierProvider.notifier).state;
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
        child: products.when(
          data: (data) {
            final filteredProducts = data
                .where(
                  (product) => product.name
                      .toLowerCase()
                      .contains(ref.watch(searchTermProvider).toLowerCase()),
                )
                .toList();
            return ListView.builder(
              itemCount: filteredProducts.isEmpty ? 1 : filteredProducts.length,
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
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      trailing: const Icon(
                        Icons.touch_app_outlined,
                        color: Colors.red,
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        'Target: ${((product.target.toDouble()) * ((workingHours - allowance) / 7.00)).ceil()}',
                      ),
                      onTap: () async {
                        final selectedProductName = product.name;
                        ref.read(selectedProductProvider.notifier).state.state =
                            selectedProductName;
                        textEditingController.text =
                            selectedProductName; // Update the controller's text
                        ref.read(showListProvider.notifier).state = false;
                        ref.read(focusNodeProvider).unfocus();
                        await Hive.box('settings')
                            .put('selectedProduct', product);

// Update the targetProvider state when a product is selected
                        final productTarget = ((product.target.toDouble()) *
                                ((workingHours - allowance) / 7.00))
                            .ceil();
                        await ref
                            .read(targetProvider.notifier)
                            .updateTarget(productTarget);

                        await repo.saveSelectedProduct(
                          SelectedProduct(
                            name: product.name,
                            selectedDate: DateTime.now(),
                            target: productTarget,
                          ),
                        );
                      },
                      onLongPress: () async {
                        // Show the DeleteItem dialog
                        await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              DeleteItem(productName: product.name),
                        );
                      },
                    ),
                  );
                }
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('Error: $error'),
        ),
      ),
    );
  }
}
