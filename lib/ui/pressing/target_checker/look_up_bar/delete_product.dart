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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.done, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Deletion completed successfully!'),
                        ],
                      ),
                      duration: Duration(
                        seconds: 2,
                      ), // Adjust duration as needed
                    ),
                  );
                  context.pop(); // Close the dialog after successful deletion
                });
              },
              icon: const Icon(Icons.done),
            ),
            IconButton(
              onPressed: () async {
                context.pop();
              },
              icon: const Icon(Icons.cancel_outlined),
            ),
          ],
        ),
      ],
    );
}
