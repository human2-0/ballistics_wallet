import 'package:ballistics_wallet_flutter/models/selected_product_history.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class LastSelectedProducts extends ConsumerWidget {
  const LastSelectedProducts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(lastSelectedProductProvider);
    final allowance = ref.watch(allowanceProvider);
    final userState = ref.watch(userNotifierProvider.notifier).state;
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
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(33),
                  color: Colors.white,
                ),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('Target: ${product.target}'),
                  trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () async {
                        await ref
                            .read(lastSelectedProductProvider.notifier)
                            .deleteSelectedProductByName(product.name);
                      },),
                  onTap: () async {
                    final selectedProductName = product.name;

                    ref.read(selectedProductProvider.notifier).state.state =
                        selectedProductName;
                    final productTarget = ((product.target.toDouble()) *
                            ((workingHours - allowance) / 7.00))
                        .ceil();
                    ref
                        .read(targetProvider.notifier)
                        .updateTarget(productTarget);
                    textEditingController.text =
                        selectedProductName; // Update the controller's text
                    ref.read(showListProvider.notifier).state = false;
                    ref.read(focusNodeProvider).unfocus();
                    await Hive.box('settings').put('selectedProduct', product);

                    await ref
                        .read(lastSelectedProductProvider.notifier)
                        .saveSelectedProduct(
                          SelectedProduct(
                            name: product.name,
                            selectedDate: DateTime.now(),
                            target: productTarget,
                          ),
                        );
                  },
                  // Add any additional fields and UI customizations you need here...
                ),
              );
            },
          ),),
    );
  }
}
