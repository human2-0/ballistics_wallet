import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../repository/pressing_repository.dart';

class AddProductDialog extends ConsumerStatefulWidget {

  const AddProductDialog({super.key});

  @override
  _AddProductDialogState createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.35,
        width: MediaQuery.of(context).size.width * 0.80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const Text("Add a new product"),
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target'),
              keyboardType: TextInputType.number,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    final String productName = productNameController.text;
                    final String targetString = targetController.text;

                    if (productName.isEmpty) {
                      return;
                    }

                    final int? target = int.tryParse(targetString);
                    if (target == null) {
                      return;
                    }

                    try {
                      await ref.read(pressingRepositoryProvider).addProduct(productName, target);
                      ref.read(productUpdateProvider.notifier).update();
                      Navigator.of(context).pop();
                    } catch (e) {}
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
