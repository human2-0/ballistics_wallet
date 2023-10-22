import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/selected_product_history.dart';
import '../repository/pressing_db_repository.dart';

final pressingRepositoryProvider = Provider<PressingRepository>((ref) {
  return PressingRepository();
});

final last7ProductsProvider = StreamProvider<List<SelectedProduct>>((ref) {
  final box = Hive.box<SelectedProduct>('selected_products');
  return box.watch().map((event) => box.values.toList());
});