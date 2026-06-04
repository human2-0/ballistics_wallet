import 'package:ballistics_wallet_flutter/custom_widgets/app_notification.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:ballistics_wallet_flutter/providers/rive_file_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rive/rive.dart' as rive; // Import the Rive package

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final riveFileName = 'assets/rive/loading_minimum_circle.riv';
  rive.RiveWidgetController? _riveController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRiveFile());
  }

  Future<void> _loadRiveFile() async {
    try {
      final riveFile = await ref.read(riveFileProvider);
      final controller = rive.RiveWidgetController(
        riveFile,
        artboardSelector: rive.ArtboardSelector.byName('login'),
        stateMachineSelector: rive.StateMachineSelector.byName('Login State'),
      );
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _riveController = controller;
      });
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to load Rive login animation: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _riveController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, state) {
      if (state is LoginStateError) {
        showAppNotification(
          context,
          state.error,
          type: AppNotificationType.error,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          if (_riveController != null)
            Positioned.fill(
              child: rive.RiveWidget(
                controller: _riveController!,
                fit: rive.Fit.cover,
              ),
            ),
          Column(
            children: [
              const SizedBox(height: 64),
              Padding(
                padding: const EdgeInsets.all(10),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Opacity(
                          opacity: 0.5,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.3 * 255,
                                  ),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.deepPurple,
                                  Colors.purple,
                                  Colors.pink,
                                ],
                              ),
                            ),
                            child: const Text(
                              'Ballistics Pocket',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 30,
                                fontFamily: 'YourFontHere',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(loginControllerProvider.notifier)
                        .loginWithGoogle();
                  },
                  child: Row(
                    children: [
                      Image.asset('assets/icon/google_icon.png', height: 32),
                      const SizedBox(width: 8),
                      const Text('Sign in with Google'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
