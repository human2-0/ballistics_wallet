import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers/states/login_controller.dart';


class ProtectScreen extends ConsumerStatefulWidget {
  const ProtectScreen({super.key});

  @override
  ConsumerState<ProtectScreen> createState() => _ProtectState();
}

class _ProtectState extends ConsumerState<ProtectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "It seems like you're lost, please sign out. LUSH people only here.",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(loginControllerProvider.notifier).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}