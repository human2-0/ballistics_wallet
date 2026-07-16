// lib/services/app_initializer.dart

import 'dart:async'; // for Zone, used to detect test environment

import 'package:ballistics_wallet_flutter/firebase_options.dart';
import 'package:ballistics_wallet_flutter/services/crash_reporting_service.dart';
import 'package:ballistics_wallet_flutter/services/work_timeline_notification_service.dart';
import 'package:ballistics_wallet_flutter/utilities.dart'; // for initHive()
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Coordinates app startup services before the Flutter widget tree is mounted.
class AppInitializer {
  /// Ensures a single instance for initialization.
  AppInitializer._();

  /// Shared initializer used by `main`.
  static final AppInitializer instance = AppInitializer._();

  static bool _gsiInitAttempted = false;
  static bool _gsiInitialized = false;

  /// Called by `main.dart` to run all necessary setup steps once.
  Future<void> initialize() async {
    await _initializeFirebase();
    if (!_runningInTestEnvironment()) {
      await CrashReportingService.instance.initialize();
    }
    await initHive();
    await WorkTimelineNotificationService.instance.initialize();
  }

  /// Initialize Google Sign-In (v7 API) without going through AuthRepository.
  /// On Android, you MUST pass the Web client ID as [serverClientId].
  static Future<void> initializeGoogleSignIn({
    String? clientId, // iOS/macOS/Web
    String? serverClientId, // Android requires the Web client ID here
  }) async {
    if (_gsiInitAttempted) return; // idempotent
    _gsiInitAttempted = true;

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (serverClientId == null || serverClientId.isEmpty)) {
      throw Exception(
        'Google Sign-In misconfigured: serverClientId (Web client ID) is '
        'required on Android.',
      );
    }

    try {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _gsiInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize failed: $e');
      rethrow;
    }
  }

  /// Probe Google Sign-In configuration without UI.
  /// Returns true if initialized and no fatal configuration error occurs.
  static Future<bool> probeGoogleSignIn() async {
    try {
      if (!_gsiInitialized) {
        debugPrint('probeGoogleSignIn: GoogleSignIn not initialized yet.');
        return false;
      }
      await GoogleSignIn.instance.attemptLightweightAuthentication();
      return true;
    } on FormatException catch (e) {
      debugPrint('probeGoogleSignIn error: $e');
      return false;
    }
  }

  static Future<void> _initializeFirebase() async {
    // Prevent duplicate initialization (hot restart, tests, multi-entry).
    final needsInit = Firebase.apps.isEmpty;

    if (_runningInTestEnvironment()) {
      if (needsInit) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'testApiKey',
            appId: 'testAppId',
            projectId: 'testProjectId',
            messagingSenderId: 'testSenderId',
          ),
        );
      }
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      return;
    }

    if (needsInit) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  static bool _runningInTestEnvironment() =>
      Zone.current.toString().contains('test');
}
