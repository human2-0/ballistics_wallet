import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_controller.dart';
import 'package:ballistics_wallet_flutter/providers/auth_providers/states/login_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  rive.Artboard? _artboard;
  rive.StateMachineController? _stateMachineController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async => _loadRiveFile());
  }

  Future<void> _loadRiveFile() async {
    final data = await rootBundle.load(riveFileName);
    final file = rive.RiveFile.import(data);
    final artboard = file.artboardByName('login')!;
    final controller = rive.StateMachineController.fromArtboard(artboard, 'Login State')!;

    artboard.addController(controller);

    setState(() {
      _artboard = artboard;
      _stateMachineController = controller;
    });
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, state) {
      if (state is LoginStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error),
          ),
        );
      }
    });


    return Scaffold(
      body: Stack(
        children: [
          if (_artboard != null)
            Positioned.fill(
              child: rive.Rive(
                artboard: _artboard!,
                fit: BoxFit.cover,
              ),
            ),
          Column(
            children: [
              const SizedBox(height: 64,),
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
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.deepPurple, Colors.purple, Colors.pink],
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
                    await ref.read(loginControllerProvider.notifier).loginWithGoogle();
                  },
                  child: Row(
                    children: [
                      Image.asset('assets/icon/google_icon.png', height: 32),
                      const SizedBox(width: 8,),
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


// class LoginScreen extends ConsumerStatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   ConsumerState<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends ConsumerState<LoginScreen> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   late StateMachineController _controller; // Controller for Rive animation
//   Artboard? _artboard; // Rive Artboard
//
//   // Method to load the Rive file
//   Future<void> _loadRiveFile() async {
//     final data = await rootBundle.load('assets/rive/loading_minimum_circle.riv'); // Adjust the path to your Rive file
//     final file = RiveFile.import(data);
//
//     setState(() {
//       _artboard = file.mainArtboard
//         ..addController(_controller = StateMachineController('login')); // Change 'idle' to the animation name you want to play
//     });
//     }
//
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(()async =>  _loadRiveFile());
//
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     ref.listen<LoginState>(loginControllerProvider, (previous, state) {
//       if (state is LoginStateError) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(state.error),
//           ),
//         );
//       }
//     });
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           if (_artboard != null) // Ensure the artboard is loaded before displaying it
//             Rive(
//               artboard: _artboard!,
//               fit: BoxFit.contain,
//             ),
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.all(10),
//               child: ListView(
//                 shrinkWrap: true,
//                 children: <Widget>[
//
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
