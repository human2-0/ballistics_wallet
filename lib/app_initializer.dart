// lib/services/app_initializer.dart

import 'dart:async'; // for Zone, used to detect test environment
import 'package:ballistics_wallet_flutter/firebase_options.dart';
import 'package:ballistics_wallet_flutter/utilities.dart'; // for initHive()
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rive/rive.dart';

class AppInitializer {
  /// Ensures a single instance for initialization.
  AppInitializer._();
  static final AppInitializer instance = AppInitializer._();

  /// Called by `main.dart` to run all necessary setup steps once.
  Future<void> initialize() async {
    await _initializeFirebase();
    await initHive();
    await RiveFile.initialize();
  }

  static Future<void> _initializeFirebase() async {
    if (_runningInTestEnvironment()) {
      // Use Firebase emulator or mock settings
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'testApiKey',
          appId: 'testAppId',
          projectId: 'testProjectId',
          messagingSenderId: 'testSenderId',
        ),
      );
      // Setup emulators
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    } else {
      // Use real initialization settings
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static bool _runningInTestEnvironment() =>
      Zone.current.toString().contains('test');
}
