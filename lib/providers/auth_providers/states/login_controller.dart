import 'package:ballistics_wallet_flutter/providers/auth_providers/auth_provider.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/providers/router_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginController extends StateNotifier<LoginState> {
  LoginController(this.ref) : super(const LoginStateInitial());

  final Ref ref;

  Future<void> login(String email, String password) async {
    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email,
            password,
          );
      state = const LoginStateInitial();
    } on FormatException catch (e) {
      state = LoginStateError(e.toString());
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const LoginStateInitial();
  }

  Future<void> loginWithGoogle() async {
    state = const LoginStateLoading();  // Indicate loading (good practice)
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const LoginStateSuccess();
      ref.read(toastMessageProvider.notifier).state = "Welcome on board, Lush's Warrior!";
    } on FormatException catch (e, st) {
      state = LoginStateError(e.toString());                    // NEW
      debugPrintStack(label: e.toString(), stackTrace: st);     // optional
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>(LoginController.new);
