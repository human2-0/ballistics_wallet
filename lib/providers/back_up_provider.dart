import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/repository/back_up_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupManagerProvider = StateNotifierProvider<BackupManager, BackupState>((ref) {
  // Access the AuthRepository using ref.watch or ref.read
  final authRepository = ref.watch(authRepositoryProvider);
  return BackupManager(authRepository);
});
