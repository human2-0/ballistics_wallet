import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/models/selected_product.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:ballistics_wallet_flutter/repository/target_check_repository.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/target_check/look_up_bar/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reselects last-selected tab when tapped while focused', (
    tester,
  ) async {
    final numberController = TextEditingController();
    final selectedProduct = SelectedProduct(
      date: DateTime(2026),
      productInfo: ProductInfo(
        productName: 'Test product',
        imageName: 'question',
        target: 10,
        product: [const Pressing('', 0, 0)],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        lastSelectedProductProvider.overrideWith(
          (ref) => LastSelectedProductNotifier(
            initialProducts: [selectedProduct],
            loadFromStorage: false,
          ),
        ),
      ],
    );
    addTearDown(() {
      numberController.dispose();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SearchProductBar(numberController: numberController),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      container.read(productListSourceProvider),
      ProductListSource.lastSelected,
    );

    container.read(productListSourceProvider.notifier).state =
        ProductListSource.allProducts;
    await tester.pump();
    expect(
      container.read(productListSourceProvider),
      ProductListSource.allProducts,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      container.read(productListSourceProvider),
      ProductListSource.lastSelected,
    );
  });
}
