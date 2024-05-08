// license_screen.dart
import 'package:ballistics_wallet_flutter/ui/pressing/profile/oss_licenses.dart';
import 'package:flutter/material.dart';

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
       backgroundColor: Colors.orange[300],
        title: const Text('Licenses' ,style: TextStyle(color: Colors.white),),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Ballistics Pocket License'),
          ),
          const Divider(),
          const BallisticsPocketLicense(),
          const Divider(),
          ListTile(
            title: const Text('List of Third-Party Licenses' ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<Widget>(
                  builder: (context) => const ThirdPartyLicensesListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BallisticsPocketLicense extends StatelessWidget {
  const BallisticsPocketLicense({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ballistics Pocket License',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              '''
Ballistics Pocket License

Copyright (c) 2024 Mateusz Dwornikiewicz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to use the Software strictly for personal and community purposes only, subject to the following conditions:

1. **Monetization:**
   - The Software shall not be used for any commercial purposes, including but not limited to selling, reselling, placing ads, or any other form of monetization.

2. **Modification:**
   - The Software code shall not be modified, altered, or adapted without prior written permission from Mateusz Dwornikiewicz.
   - Data stored in the Software can be modified by the end-users for personal purposes.

3. **Distribution:**
   - Redistribution of the Software is allowed for personal and community use only, provided that this license notice is included in all copies or substantial portions of the Software.

4. **Disclaimer:**
   - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.
   - IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

5. **Intellectual Property:**
   - Mateusz Dwornikiewicz retains all intellectual property rights to the Software.
   - Unauthorized use, modification, or distribution of the Software code is strictly prohibited.
   
   ### Third-Party Licenses
This project uses third-party libraries that are licensed under their respective terms. Please refer to their licenses in the third-party licenses section.
              ''',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdPartyLicensesListScreen extends StatelessWidget {
  const ThirdPartyLicensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[300],
        title: const Text('Third-Party Licenses',style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        children: allDependencies
            .map(
              (package) => ListTile(
                title: Text(package.name),
                subtitle: Text(package.version),
                onTap: () async => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ThirdPartyLicenseDetailScreen(package: package),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ThirdPartyLicenseDetailScreen extends StatelessWidget {
  const ThirdPartyLicenseDetailScreen({required this.package, super.key});

  final Package package;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(backgroundColor: Colors.orange[300],
        title: Text(package.name, style: const TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Version: ${package.version}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'License:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  package.license ?? 'License information not available.',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
