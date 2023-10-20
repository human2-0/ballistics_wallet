import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final requiredAmountProvider = StateProvider<double>((ref) => 0.0);
final amountPerBatchProvider = StateProvider<int>((ref) => 0);
