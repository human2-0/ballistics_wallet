import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp() : super();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Ballistics Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)
      ),

      routerConfig: router,
    );
  }
}

MaterialColor blackMaterialColor = const MaterialColor(
  0xFF000000, // Primary color value
  <int, Color>{
    50: Color(0xFFE5E5E5),
    100: Color(0xFFBFBFBF),
    200: Color(0xFF999999),
    300: Color(0xFF737373),
    400: Color(0xFF525252),
    500: Color(0xFF313131),
    600: Color(0xFF2B2B2B),
    700: Color(0xFF242424),
    800: Color(0xFF1D1D1D),
    900: Color(0xFF131313),
  },
);
