import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/pressing_db_provider.dart';
import '../../../../providers/target_check_provider.dart';
import '../../../../repository/target_check_repository.dart';

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                offset: const Offset(4, 4), // changes position of shadow
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
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
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
                                decoration: const InputDecoration(
                                    labelText: 'Product Name'),
                              ),
                              TextField(
                                controller: targetController,
                                decoration:
                                    const InputDecoration(labelText: 'Target'),
                                keyboardType: TextInputType.number,
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
                                          productNameController.text;
                                      final String targetString =
                                          targetController.text;

                                      if (productName.isEmpty) {
                                        return;
                                      }

                                      final int? target =
                                          int.tryParse(targetString);
                                      if (target == null) {
                                        return;
                                      }

                                      try {
                                        await ref
                                            .read(pressingRepositoryProvider)
                                            .addProduct(productName, target);
                                        ref
                                            .read(
                                                productUpdateProvider.notifier)
                                            .update();
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
                    });
              }),
        ),
      ),
    );
  }
}
