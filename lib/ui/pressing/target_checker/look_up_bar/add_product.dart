import 'package:ballistics_wallet_flutter/providers/pressing_db_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  AddProductDialogState createState() => AddProductDialogState();
}

class AddProductDialogState extends ConsumerState<AddProductDialog> {
  // final TextEditingController productNameController = TextEditingController();
  final TextEditingController targetController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final productNameController = ref.watch(textEditingControllerProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(33),
        color: Colors.white,
      ),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: ListTile(
        title: const Text("Not found what you're looking for?"),
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
              await showDialog(
                context: context,
                builder: (context) =>
                    Dialog(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.35,
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.80,
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            const Text('Add a new product'),
                            TextField(
                              controller: productNameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',),
                            ),
                            TextField(
                              controller: targetController,
                              decoration: const InputDecoration(
                                labelText: 'Target',),
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
                                    final productName =
                                        productNameController.text;
                                    final targetString =
                                        targetController.text;

                                    if (productName.isEmpty) {
                                      return;
                                    }

                                    final target =
                                    int.tryParse(targetString);
                                    if (target == null) {
                                      return;
                                    }

                                    try {
                                      await ref
                                          .read(
                                        pressingRepositoryProvider,)
                                          .addProduct(
                                        productName, target,);
                                      ref
                                          .read(productUpdateProvider
                                          .notifier,)
                                          .update();
                                      Navigator.of(context).pop();
                                    } on FormatException catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                          Text('Error: ${e.message}'),
                                          behavior:
                                          SnackBarBehavior.floating,
                                          duration:
                                          const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),);
            },),
        ),
      ),
    );
  }
}
