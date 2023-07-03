import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/states/login_states.dart';
import '../providers/states/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

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
          Image.asset(
            'assets/login_screen.jpg',
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
              Container(
              alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: Opacity(
                    opacity: 0.5, // Adjust the opacity as desired
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(33),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.deepPurple.withOpacity(1), // Adjust the opacity as desired
                            Colors.purple.withOpacity(1), // Adjust the opacity as desired
                            Colors.pink.withOpacity(1), // Adjust the opacity as desired
                          ],
                        ),
                      ),
                      child: const Text(
                        'Ballistics Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 30,
                          fontFamily: 'TrippyFont', // Replace 'TrippyFont' with the desired font
                        ),
                      ),
                    ),
                  ),
                ),
              ),
                const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          ref.read(loginControllerProvider.notifier).loginWithGoogle();
                        },
                        child: const Text('Sign in with Google'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );


  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class EmailValidator {
  static bool validate(String email) {
    // Check if the email address is empty
    if (email.isEmpty) {
      return false;
    }
    // Check if the email address has the correct format
    RegExp regex = RegExp(r"^[a-zA-Z\d._%+-]+@[a-zA-Z\d.-]+\.[a-zA-Z]{2,}$");
    if (!regex.hasMatch(email)) {
      return false;
    }
    // The email address is valid
    return true;
  }
}
