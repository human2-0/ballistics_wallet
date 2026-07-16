import 'package:ballistics_wallet_flutter/models/product_info.dart';
import 'package:ballistics_wallet_flutter/providers/controllers.dart';
import 'package:ballistics_wallet_flutter/providers/product_info_provider.dart';
import 'package:ballistics_wallet_flutter/providers/target_check_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Applies a product selection without allowing persistence to keep the lookup
/// field focused while the selected-product history is refreshed.
Future<void> selectTargetCheckProduct(
  WidgetRef ref,
  ProductInfo product,
) async {
  // Closing the lookup and releasing its input connection must happen before
  // any provider/controller updates or Hive work trigger rebuilds.
  dismissTargetCheckInputs(ref);

  ref.read(focusedProductProvider.notifier).state = product;
  ref.read(targetProvider.notifier).state = product.target;
  ref.read(productNameControllerProvider.notifier).controller.text =
      product.productName;

  final history = ref.read(lastSelectedProductProvider.notifier);
  await history.saveSelectedProduct(product);
}
