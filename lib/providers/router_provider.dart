
import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/ui/login_screen.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/bottom_app_bar.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/new_wallet/wallet_root.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check.dart';
import 'package:ballistics_wallet_flutter/ui/protect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


final toastMessageProvider = StateProvider<String>((ref)=> '');

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

  RouterNotifier(this._ref) {
    _ref.listen<LoginState>(
      loginControllerProvider,
          (_, __) => notifyListeners(),
    );
  }
  final Ref _ref;

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
    // Check if the user is already on the '/' route
    if (user != null && userData != null && userData.userEmailAddress != null) {
      final email = userData.userEmailAddress.toString();
      final allowedDomains = ['gmail.com', 'lush.co.uk'];
      if (email.isNotEmpty && allowedDomains.any((domain) => email.endsWith('@$domain'))) {
        // User is already authenticated and on the home route, no need to redirect
        return null;
      }
    }

    // For other cases, perform redirection logic as before
    if (user == null) {
      return '/login';
    }

    final email = userData?.userEmailAddress ?? '';
    final allowedDomains = ['gmail.com', 'lush.co.uk'];
    if (email.isEmpty || !allowedDomains.any((domain) => email.endsWith('@$domain'))) {
      return '/login';
    }

    // If email is valid and not on the home route, redirect to '/'
    return '/';
  }
}
