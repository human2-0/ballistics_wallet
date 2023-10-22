import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';
import '../../../../repository/users_repository.dart';
import 'add_product.dart';

class ProductsListSuggested extends ConsumerWidget {
  const ProductsListSuggested({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updated = ref.watch(productUpdateProvider);
    final products = ref.watch(productsProvider(updated));

    final userState = ref.watch(userNotifierProvider.notifier).state;
    final allowance = ref.watch(allowanceProvider);
    final double workingHours = userState.workingHours ?? 0.0;

    final textEditingController = ref.watch(textEditingControllerProvider);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(33),
          ),
          color: Colors.orange[50],
        ),
        child: products.when(
          data: (data) {
            final filteredProducts = data
                .where((product) => product.name
                    .toLowerCase()
                    .contains(ref.watch(searchTermProvider).toLowerCase()))
                .toList();
            return ListView.builder(
              itemCount: filteredProducts.isEmpty ? 1 : filteredProducts.length,
              itemBuilder: (context, index) {
                if (filteredProducts.isEmpty) {
                  return AddProductDialog();
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
                      title: Text(product.name),
                      subtitle: Text(
                          'Target: ${((product.target.toDouble()) * ((workingHours - allowance) / 7.00)).ceil()}'),
                      onTap: () {
                        String selectedProductName = product.name;
                        ref
                            .read(selectedProductProvider.notifier)
                            .state
                            .state = selectedProductName;
                        textEditingController.text = selectedProductName
                            .toString(); // Update the controller's text
                        ref.read(showListProvider.notifier).state = false;
                        ref.read(focusNodeProvider).unfocus();
                        Hive.box('settings').put('selectedProduct', product);

// Update the targetProvider state when a product is selected
                        int productTarget = (((product.target.toDouble()) *
                                ((workingHours - allowance) / 7.00))
                            .ceil());
                        ref
                            .read(targetProvider.notifier)
                            .updateTarget(productTarget);
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
