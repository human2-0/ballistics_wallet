import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Configures production crash reporting and Analytics breadcrumbs.
class CrashReportingService {
  CrashReportingService._();

  /// Shared crash reporting service.
  static final CrashReportingService instance = CrashReportingService._();

  bool _breadcrumbsEnabled = false;
  bool _initialized = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Navigation observers that provide screen breadcrumbs in crash reports.
  List<NavigatorObserver> get navigatorObservers =>
      _breadcrumbsEnabled
          ? <NavigatorObserver>[
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ]
          : const <NavigatorObserver>[];

  /// Enables collection and global error handlers for release builds.
  Future<void> initialize() async {
    if (_initialized || !_isSupported) return;
    _initialized = true;

    final analytics = FirebaseAnalytics.instance;
    final crashlytics = FirebaseCrashlytics.instance;

    // Keep local development and automated tests out of production metrics.
    await analytics.setAnalyticsCollectionEnabled(kReleaseMode);
    await crashlytics.setCrashlyticsCollectionEnabled(kReleaseMode);

    if (!kReleaseMode) return;

    _breadcrumbsEnabled = true;
    await crashlytics.setCustomKey('platform', defaultTargetPlatform.name);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(crashlytics.recordFlutterFatalError(details));
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
      return true;
    };
  }

  /// Records a handled failure that should still be visible in production.
  Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    required String reason,
  }) async {
    if (!_isSupported || !kReleaseMode) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
    );
  }
}
