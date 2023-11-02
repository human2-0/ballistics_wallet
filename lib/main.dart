// Dart imports

// Local imports
import 'package:ballistics_wallet_flutter/firebase_options.dart';
// Package imports
import 'package:ballistics_wallet_flutter/providers/auth_providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  await _initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHive();
  await loadDataFromCSV();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

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
