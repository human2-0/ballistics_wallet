
import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/bottom_app_bar.dart';
import 'package:ballistics_wallet_flutter/ui/protect_screen.dart';
import '../ui/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/pressing/split_check/split_check.dart';




final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  // Here you are watching the user.
  final user = ref.watch(authStateProvider);
  final userData = ref.watch(authRepositoryProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    routes: router._routes,
    redirect: (context, state) => router._redirect(user, userData),
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<LoginState>(
      loginControllerProvider,
          (_, __) => notifyListeners(),
    );
  }

  List<GoRoute> get _routes =>
      [
        GoRoute(
          name: 'login',
          builder: (context, state) => const LoginScreen(),
          path: '/login',
        ),
        GoRoute(
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          path: '/',
        ),
        GoRoute(
          name: 'split',
          builder: (context, state) {
            final requiredAmount = state.queryParameters['requiredAmount'];
            return SplitCheck(
              requiredAmount: requiredAmount == null ? 0 : int.parse(requiredAmount),
            );
          },
          path: '/split',

        ),
        GoRoute(
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
          path: '/loading',
        ),
        GoRoute(
          name: 'protect',
          builder: (context, state) => const ProtectScreen(),
          path: '/protect',
        ),
      ];


  FutureOr<String?> _redirect(user, userData) async {
    // The logic remains the same.
    if (user == null) {
      return '/login';
    } else {
      final email = userData.userEmailAddress ?? '';
      // Add the check for an empty string here
      if (email.isEmpty || !email.endsWith('@lush.co.uk')) {
        return '/login';
      } else {
        return '/';
      }
    }
  }
}