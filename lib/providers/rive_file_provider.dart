// rive_file_provider.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';

final riveFileProvider = Provider<Future<RiveFile>>((ref) async {
  final data = await rootBundle.load('assets/rive/loading_minimum_circle.riv');
  return RiveFile.import(data);
});
