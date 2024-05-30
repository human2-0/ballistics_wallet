// Dart imports

// Local imports
import 'dart:async';

import 'package:ballistics_wallet_flutter/firebase_options.dart';
import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
// Package imports
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:ballistics_wallet_flutter/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeFirebase();
}

Future<void> initializeFirebase() async {
  if (runningInTestEnvironment()) {
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
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

bool runningInTestEnvironment() {
  return Zone.current.toString().contains('test');
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
        await preloadImages(context);
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
