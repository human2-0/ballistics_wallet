import 'package:ballistics_wallet_flutter/repository/outdated_pressing_db_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pressingRepositoryProvider = Provider<PressingRepository>((ref) => PressingRepository());
