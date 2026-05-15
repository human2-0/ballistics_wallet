// rive_file_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

final riveFileProvider = Provider<Future<File>>((ref) async {
  final file = await File.asset(
    'assets/rive/loading_minimum_circle.riv',
    riveFactory: Factory.flutter,
  );
  if (file == null) {
    throw StateError('Unable to load Rive file.');
  }
  ref.onDispose(file.dispose);
  return file;
});
