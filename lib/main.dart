import 'dart:async';

import 'package:ballistics_wallet_flutter/app_initializer.dart';
import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// We intentionally read a compile-time define here.
// ignore: do_not_use_environment

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.instance.initialize();
  await AppInitializer.initializeGoogleSignIn(
    serverClientId:
        '291226983840-j20si3ikj5908lo23l2en7n1km13neaj.apps.googleusercontent.com', // <-- USE THE Web OAuth client_id (not the client_secret filename)
    // clientId: 'OPTIONAL_IOS_OR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
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
      unawaited(ref.read(riveFileProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Ballistics Wallet',
      debugShowCheckedModeBanner: false,
      builder:
          (context, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox.shrink(),
          ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      routerConfig: router,
    );
  }
}
