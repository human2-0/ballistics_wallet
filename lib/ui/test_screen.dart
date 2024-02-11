import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestScreen extends ConsumerStatefulWidget {
  const TestScreen({super.key});

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  @override
  Widget build(BuildContext context) {

    final productList = ref.watch(productInfoProvider);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Add other widgets here if needed
            ListView.builder(
              itemCount: productList.length,
              shrinkWrap: true, // Allows ListView.builder to be part of another scrollable widget
              physics: const NeverScrollableScrollPhysics(), // Disables scrolling within the ListView.builder
              itemBuilder: (context, index) {
                final product = productList[index];
                return ListTile(
                  leading: const Icon(Icons.radio_button_checked),
                  title: Text(product.productName),
                  subtitle: Text('Target: ${product.target}, Image Name: ${product.imageName}'),
                  // Add more details from your ProductInfo and Product model here if needed
                  onTap: () {
                    // Handle tap if necessary
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
