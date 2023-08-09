import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDirectory =
  await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  //
  var box = await Hive.openBox('Products');

  // Clear all existing data in the box
  await box.clear();

  final rawData = await rootBundle.loadString('new_targets.csv');
  List<List<dynamic>> rows = const CsvToListConverter().convert(rawData);

  for (var row in rows) {
    var productName = row[0];

    if (productName is String && productName.isNotEmpty) {
      var targetString = row.sublist(1).join();
      targetString = targetString.replaceAll(RegExp(r'[,"]'), '');

      var target = int.tryParse(targetString);

      if (target != null && target != 0) {
        box.put(productName, target);
      }
    }
  }




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

class LifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Hive.close();
    }
  }
}
