import 'dart:async';

import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/services/crash_reporting_service.dart';
import 'package:ballistics_wallet_flutter/ui/login_screen.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/bottom_app_bar.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/ask_for_feature.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/licenses.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/privacy.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/profile/terms_of_use.dart';
import 'package:ballistics_wallet_flutter/ui/pressing/split_check/split_check_view.dart';
import 'package:ballistics_wallet_flutter/ui/protect_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final toastMessageProvider = StateProvider<String>((ref) => '');

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  final router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    observers: [
      KeyboardDismissNavigatorObserver(),
      ...CrashReportingService.instance.navigatorObservers,
    ],
    routes: notifier._routes,
    refreshListenable: notifier,
    redirect: notifier._redirect,
  );

  ref.onDispose(() {
    router.dispose();
    notifier.dispose();
  });
  return router;
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref
      ..listen<AsyncValue<User?>>(
        authStateProvider,
        (_, _) => notifyListeners(),
      )
      ..listen<LoginState>(
        loginControllerProvider,
        (_, _) => notifyListeners(),
      );
  }
  final Ref _ref;

  List<GoRoute> get _routes => [
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
      builder: (context, state) => const SplitCheck(),
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
      builder: (context, state) => const SendFeatureEmailScreen(),
      path: '/askforfeature',
    ),
    GoRoute(
      name: 'reportbug',
      builder: (context, state) => const SendFeatureEmailScreen(),
      path: '/reportbug',
    ),
  ];

  FutureOr<String?> _redirect(BuildContext context, GoRouterState state) =>
      authRedirectFor(
        authState: _ref.read(authStateProvider),
        location: state.matchedLocation,
      );
}

@visibleForTesting
String? authRedirectFor({
  required AsyncValue<User?> authState,
  required String location,
}) {
  // Do not expose an interactive screen until Firebase has restored the
  // session. This removes the startup window where auth could replace the
  // home tree while a text field was focused.
  if (authState.isLoading) {
    return location == '/loading' ? null : '/loading';
  }

  final email = authState.asData?.value?.email ?? '';
  if (!_isAllowedEmail(email)) {
    return location == '/login' ? null : '/login';
  }

  if (location == '/login' || location == '/loading') {
    return '/';
  }
  return null;
}

bool _isAllowedEmail(String email) {
  const allowedDomains = {'gmail.com', 'lush.co.uk'};
  final separator = email.lastIndexOf('@');
  if (separator <= 0 || separator == email.length - 1) return false;
  return allowedDomains.contains(email.substring(separator + 1).toLowerCase());
}

/// Prevents a platform keyboard from remaining attached to a field after its
/// route has been replaced or removed.
class KeyboardDismissNavigatorObserver extends NavigatorObserver {
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismissKeyboard();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismissKeyboard();
  }
}
