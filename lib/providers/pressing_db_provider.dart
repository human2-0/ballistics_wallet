import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/pressing_db_repository.dart';

final pressingRepositoryProvider = Provider<PressingRepository>((ref) {
  return PressingRepository();
});