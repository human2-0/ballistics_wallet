import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';
import '../../../../repository/users_repository.dart';

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
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(33),
                      color: Colors.white,
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      title: const Text('Not found what you\'re looking for?'),
                      trailing: Container(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 16,
                              offset: const Offset(
                                  4, 4), // changes position of shadow
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[50]!,
                              Colors.orange[200]!,
                              Colors.orange[300]!,
                            ],
                            stops: const [
                              0.0,
                              0.5,
                              0.9,
                            ],
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(33),
                          ),
                        ),
                        child: IconButton(
                            icon: const Icon(Icons.add),
                            color: Colors.brown[400],
                            tooltip: 'Add product',
                            onPressed: () async {
                              final productNameController =
                                  TextEditingController();
                              final targetController = TextEditingController();

                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.35,
                                        // 30% of screen height
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.80,
                                        // 75% of screen width
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: <Widget>[
                                            const Text("Add a new product"),
                                            TextField(
                                              controller: productNameController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Product Name'),
                                            ),
                                            TextField(
                                              controller: targetController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Target'),
                                              keyboardType:
                                                  TextInputType.number,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                TextButton(
                                                  child: const Text('Cancel'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: const Text('Add'),
                                                  onPressed: () async {
                                                    final String productName =
                                                        productNameController
                                                            .text;
                                                    final String targetString =
                                                        targetController.text;

                                                    if (productName.isEmpty) {
                                                      return;
                                                    }

                                                    final int? target =
                                                        int.tryParse(
                                                            targetString);
                                                    if (target == null) {
                                                      return;
                                                    }

                                                    try {
                                                      await ref
                                                          .read(
                                                              pressingRepositoryProvider)
                                                          .addProduct(
                                                              productName,
                                                              target);
                                                      ref
                                                          .read(
                                                              productUpdateProvider
                                                                  .notifier)
                                                          .update();
                                                      Navigator.of(context)
                                                          .pop();
                                                    } catch (e) {}
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            }),
                      ),
                    ),
                  );
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
