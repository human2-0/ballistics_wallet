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
    serverClientId: '291226983840-j20si3ikj5908lo23l2en7n1km13neaj.apps.googleusercontent.com', // <-- USE THE Web OAuth client_id (not the client_secret filename)
    // clientId: 'OPTIONAL_IOS_OR_WEB_CLIENT_ID.apps.googleusercontent.com',
  );
  runApp(const ProviderScope(child: MyApp()));

}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // If you want to preload Rive files right after the first frame:
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(riveFileProvider);
    });

    return MaterialApp.router(
      title: 'Ballistics Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      routerConfig: router,
    );
  }
}
