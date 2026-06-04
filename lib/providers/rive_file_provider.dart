// rive_file_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart' as rive;

/// Loads and caches the shared Rive file used by target-check animations.
final riveFileProvider = Provider<Future<rive.File>>((ref) async {
  final file = await _loadRiveFileWithBestRenderer();
  if (file == null) {
    throw StateError('Unable to load Rive file.');
  }
  ref.onDispose(file.dispose);
  return file;
});

Future<rive.File?> _loadRiveFileWithBestRenderer() async {
  const assetPath = 'assets/rive/loading_minimum_circle.riv';

  try {
    await rive.RiveNative.init();
    if (rive.Factory.rive.isSupported) {
      return rive.File.asset(assetPath, riveFactory: rive.Factory.rive);
    }
  } on Object catch (error, stackTrace) {
    debugPrint('Rive native renderer init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    throw StateError('Rive native renderer could not be initialized.');
  }

  return rive.File.asset(assetPath, riveFactory: rive.Factory.flutter);
}
