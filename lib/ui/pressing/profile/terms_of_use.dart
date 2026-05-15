import 'package:flutter/material.dart';

class BallisticsPocketTermsOfUse extends StatelessWidget {
  const BallisticsPocketTermsOfUse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[300],
        title: const Text('Terms of Use', style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ballistics Pocket Terms of Use',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                '''
Last updated: 8 May 2024

## Acceptance of Terms
By downloading or using the Ballistics Pocket app, you agree to be bound by these Terms of Use. If you do not agree to these terms, please do not use the app.

## Changes to Terms
We reserve the right to modify these Terms of Use at any time. Your continued use of the app following the posting of changes means that you accept the new terms.

## User Responsibilities
1. **Account Information:** Users are responsible for maintaining the confidentiality of their account information.
2. **Lawful Use:** Users agree to use the app only for lawful purposes.
3. **No Commercial Use:** Users agree not to use the app for commercial purposes or resell any part of it.

## Prohibited Activities
Users are prohibited from:
- Attempting to gain unauthorized access to the app.
- Using the app for any illegal or unauthorized purpose.
- Placing advertisements within the app.
- Modifying, adapting, or reverse engineering any part of the app without permission.

## Intellectual Property Rights
All content, features, and functionality (including but not limited to the design, logos, and software) are owned by Mateusz Dwornikiewicz and are protected by copyright, trademark, and other laws. Unauthorized use of these materials is strictly prohibited.

## Disclaimers
The Ballistics Pocket app is provided "AS IS" without warranties of any kind, either express or implied. We do not guarantee the accuracy, reliability, or completeness of any information provided through the app.

## Limitation of Liability
In no event shall Mateusz Dwornikiewicz be liable for any direct, indirect, incidental, or consequential damages arising from the use or inability to use the app.

## Governing Law
These Terms of Use shall be governed by and construed in accordance with the laws of United Kingdom.

## Contact Information
If you have any questions about these Terms of Use, please contact us at:
- **Email:** devulopa@gmail.com
                ''',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
