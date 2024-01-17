import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
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
  Widget build(BuildContext context) {
    final pressingRepo = ref.read(pressingRepositoryProvider);
    return AlertDialog(
      content: Text('Would you like to permanently delete the product ${widget.productName} ?'),
      actions: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () async {
                await pressingRepo.deleteProduct(widget.productName);
                ref.read(productUpdateProvider.notifier).update();
                await ref
                    .read(lastSelectedProductProvider.notifier)
                    .deleteSelectedProductByName(widget.productName);
                if (mounted) {
                  Navigator.of(context).pop(); // Close the dialog after successful deletion
                } // Close the dialog after successful deletion
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
}
