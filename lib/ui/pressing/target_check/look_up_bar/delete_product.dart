import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeleteItem extends ConsumerStatefulWidget {
  const DeleteItem({required this.productName, super.key});
  final String productName;

  @override
  DeleteItemState createState() => DeleteItemState();
}

class DeleteItemState extends ConsumerState<DeleteItem> {
  @override
  Widget build(BuildContext context) => AlertDialog(
    content: Text(
      'Would you like to permanently delete the product ${widget.productName} ?',
    ),
    actions: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () async {
              await ref
                  .read(productInfoProvider.notifier)
                  .deleteProduct(widget.productName);
              await ref
                  .read(lastSelectedProductProvider.notifier)
                  .deleteSelectedProductByName(widget.productName);
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                showAppNotification(
                  context,
                  'Product deleted.',
                  type: AppNotificationType.success,
                  duration: const Duration(seconds: 3),
                );
                context.pop(); // Close the dialog after successful deletion
              });
            },
            icon: const Icon(Icons.done),
          ),
          IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.cancel_outlined),
          ),
        ],
      ),
    ],
  );
}
