import 'package:flutter/material.dart';

class BallisticsPocketPrivacyPolicy extends StatelessWidget {
  const BallisticsPocketPrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[300],
        title: const Text('Privacy Policy', style: TextStyle(color: Colors.white),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ballistics Pocket Privacy Policy',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                '''
Last updated: 8 May 2024

## Introduction
At Ballistics Pocket, we value your privacy and are committed to protecting your personal data. This Privacy Policy explains what information we collect, how we use it, and how we safeguard it.

## Information We Collect
### Personal Information
We do not collect or store any personal information that identifies you directly on our servers.

### Non-Personal Information
We may collect non-personal information about your device, such as:
- Device model and manufacturer
- Operating system version

## Data Security and Privacy Features
1. **End-to-End Encryption:**
   - All sensitive user data is encrypted using industry-standard end-to-end encryption.
   - Neither the developer nor anyone with access to the database can read user data.

2. **Backup Feature:**
   - Users can store their unencrypted data in their Google Drive storage through the backup feature.
   - This requires explicit permission via the app's permissions requests.

3. **Data Sharing:**
   - We do not share your data with any third-party organizations.

4. **Permissions:**
   - **Storage Access:** Required for reading and writing backup files.
   - **Internet Access:** Required for accessing Google Drive backup.

## Third-Party Services
We may use third-party services that collect non-personal information to analyze app usage and improve user experience.

- **Google Analytics:** Used to understand how users interact with the app. [Google Analytics Privacy Policy](https://policies.google.com/privacy)
- **Crashlytics:** Helps us identify and fix crashes. [Crashlytics Privacy Policy](https://firebase.google.com/support/privacy)

## Your Rights
You have the right to:
1. Access your data.
2. Correct any incorrect or incomplete data.
3. Delete your data.
4. Withdraw consent for data processing.

## Changes to This Privacy Policy
We may update this policy from time to time. Any changes will be communicated through in-app notifications or by updating this page.

## Contact Information
If you have any questions or concerns about this Privacy Policy or data practices, please contact us at:
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
