import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LastSelectedProducts extends ConsumerWidget {
  const LastSelectedProducts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(lastSelectedProductProvider);
    final allowance = ref.watch(allowanceProvider);
    final userState = ref.watch(userNotifierProvider);
    final workingHours = userState.workingHours ?? 0.0;

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
            final reversedIndex = products.length - 1 - index;
            final product = products[reversedIndex].productInfo;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(33),
                color: Colors.white,
              ),
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: ListTile(
                title: Text(product.productName),
                subtitle: Text('Target: ${product.target}'),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () async {
                    await ref
                        .read(lastSelectedProductProvider.notifier)
                        .deleteSelectedProductByName(product.productName);
                  },
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  ref.read(focusedProductProvider.notifier).state = product;

                  final productTarget = ((product.target.toDouble()) *
                          ((workingHours - allowance) / 7.00))
                      .ceil();
                  await ref
                      .read(lastSelectedProductProvider.notifier)
                      .saveSelectedProduct(
                        product,
                      );
                  await ref
                      .read(targetProvider.notifier)
                      .updateTarget(productTarget);
                  ref.read(productNameControllerProvider.notifier).controller.text = product.productName;
                  ref.read(showListProvider.notifier).state = false;
                  ref.read(focusNodeProvider).unfocus();
                },
                // Add any additional fields and UI customizations you need here...
              ),
            );
          },
        ),
      ),
    );
  }
}
