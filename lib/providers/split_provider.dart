import 'package:flutter_riverpod/flutter_riverpod.dart';

final requiredAmountProvider = StateProvider<int>((ref) => 0);
final amountPerBatchProvider = StateProvider<int>((ref) => 0);
