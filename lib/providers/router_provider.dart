
import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/repository/auth_repository.dart';
import 'package:ballistics_wallet_flutter/ui/login_screen.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/bottom_app_bar.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/ask_for_feature.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/licenses.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/privacy.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/terms_of_use.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check_view.dart';
import 'package:ballistics_wallet_flutter/ui/protect_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          builder: (context, state) => const RootBottomBar(),
          path: '/',
        ),
        GoRoute(
          name: 'split',
          builder: (context, state) {
            return const SplitCheck(
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
        GoRoute(
          name: 'privacy',
          builder: (context, state) => const BallisticsPocketPrivacyPolicy(),
          path: '/privacy',
        ),
        GoRoute(
          name: 'termsofuse',
          builder: (context, state) => const BallisticsPocketTermsOfUse(),
          path: '/termsofuse',
        ),
        GoRoute(
          name: 'license',
          builder: (context, state) => const LicenseScreen(),
          path: '/license',
        ),
        GoRoute(
          name: 'askforfeature',
          builder: (context, state) => const  SendFeatureEmailScreen(),
          path: '/askforfeature',
        ),
        GoRoute(
          name: 'reportbug',
          builder: (context, state) => const  SendFeatureEmailScreen(),
          path: '/reportbug',
        ),



      ];


  FutureOr<String?> _redirect(AsyncValue<User?>user, AuthRepository userData) async {
    // Check if the user is already on the '/' route
    final email = userData.userEmailAddress;
    final allowedDomains = ['gmail.com', 'lush.co.uk'];
    if (email.isNotEmpty && allowedDomains.any((domain) => email.endsWith('@$domain'))) {
      // User is already authenticated and on the home route, no need to redirect
      return null;
    }
    if (email.isEmpty || !allowedDomains.any((domain) => email.endsWith('@$domain'))) {
      return '/login';
    }
    final googleUser = await userData.getCurrentGoogleUser();
    if(googleUser == null){
      return '/login';
    }

    // If email is valid and not on the home route, redirect to '/'
    return '/';
  }
}
