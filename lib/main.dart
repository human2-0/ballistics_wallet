import 'dart:async';

import 'package:ballistics_wallet_flutter/app_initializer.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/custom_widgets/keyboard_dismiss_region.dart';
import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/services/crash_reporting_service.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await AppInitializer.instance.initialize();
  await AppInitializer.initializeGoogleSignIn(
    // Use the Web OAuth client ID, not the client secret filename.
    serverClientId:
        '291226983840-j20si3ikj5908lo23l2en7n1km13neaj.apps'
        '.googleusercontent.com',
    // clientId: 'OPTIONAL_IOS_OR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

/// Root application widget.
class MyApp extends ConsumerStatefulWidget {
  /// Creates the root application widget.
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_preloadRiveFile());
    });
  }

  Future<void> _preloadRiveFile() async {
    try {
      await ref.read(riveFileProvider);
    } on Object catch (error, stackTrace) {
      await CrashReportingService.instance.recordNonFatal(
        error,
        stackTrace,
        reason: 'Rive asset preload failed',
      );
      debugPrint('Rive preload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ballistics Wallet',
      debugShowCheckedModeBanner: false,
      builder:
          (context, child) =>
              KeyboardDismissRegion(child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        snackBarTheme: appSnackBarTheme(),
      ),
      routerConfig: router,
    );
  }
}
