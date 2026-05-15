import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/product_image_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides runtime product image download and Drive upload support.
final productImageRepositoryProvider = Provider<ProductImageRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ProductImageRepository(authRepository);
});
