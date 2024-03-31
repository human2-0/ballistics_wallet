import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/users_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/delete_item.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_checker/look_up_bar/edit_product.dart';
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
                onLongPress: () async {
                  final action = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Delete'),
                          onTap: () => Navigator.pop(context, 'delete'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () => Navigator.pop(context, 'edit'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.cancel),
                          title: const Text('Cancel'),
                          onTap: () => Navigator.pop(context, 'cancel'),
                        ),
                      ],
                    ),
                  );

                  // Handle the selected action
                  switch (action) {
                    case 'delete':
                      WidgetsBinding.instance
                          .addPostFrameCallback((timeStamp) async {
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => DeleteItem(
                            productName: product.productName,
                          ),
                        );
                      });

                    case 'edit':
                      WidgetsBinding.instance
                          .addPostFrameCallback((timeStamp) async {
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
                title: Text(product.productName),
                subtitle: Text('Target: ${product.target}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: Colors.red,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () async {
                        await ref
                            .read(lastSelectedProductProvider.notifier)
                            .deleteSelectedProductByName(product.productName);
                      },
                    ),
                  ],
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
                  ref
                      .read(targetProvider.notifier)
                      .state = productTarget;
                  ref
                      .read(productNameControllerProvider.notifier)
                      .controller
                      .text = product.productName;
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
