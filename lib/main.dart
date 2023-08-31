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
  await Hive.initFlutter();

  var box = await Hive.openBox('Products');

  String determineEOL() {
    if (Platform.isWindows) {
      return '\r\n';
    }
    // For other platforms like iOS, macOS, Linux, etc.
    return '\n';
  }

  String eol = determineEOL();


  try {
    final rawData = await rootBundle.loadString('new_targets.csv');
    String eol = rawData.contains('\r\n') ? '\r\n' : '\n';
    List<List<dynamic>> rows = CsvToListConverter(eol: eol).convert(rawData);

    for (var row in rows) {
      if (row != null) {

        if (row.length < 2) {
          print('Skipping row due to insufficient columns.');
          continue;
        }

        var productName = row[0]?.toString()?.trim();
        var targetString = row[1]?.toString()?.replaceAll(RegExp(r'[,"]'), '')?.trim();
        var cleanedTargetString = targetString?.replaceAll(RegExp(r'[^0-9]'), '');
        var target = int.tryParse(cleanedTargetString!);


        if (productName != null && productName.isNotEmpty) {
          var target = int.tryParse(targetString ?? '');
          if (target == null && targetString != null) {
            print('Failed to parse target value for product: $productName. Raw value: $targetString');
            for (var char in targetString.split('')) {
              print('${char}: ${char.codeUnitAt(0)}');
            }
            continue;
          }

          if (target != 0) {
            await box.put(productName, target);
            print("Added to box: $productName with value $target");
          } else {
            print('Target value is 0 for product: $productName. Skipping.');
          }
        } else {
          print('Product name is empty or null. Skipping.');
        }
      }
    }
  } catch (e) {
    print("Error occurred: $e");
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
