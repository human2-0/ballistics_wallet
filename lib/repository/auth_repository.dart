import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChange => _auth.idTokenChanges();
  String get userEmailAddress => _auth.currentUser?.email ?? '';
  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<Box<UserSettings>> _openBox() async {
    if (Hive.isBoxOpen('settings')) {
      return Hive.box<UserSettings>('settings');
    }
    return Hive.openBox<UserSettings>('settings');
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('User not found');
        case 'wrong-password':
          throw AuthException('Wrong password.');
        case 'invalid-email':
          throw AuthException('Invalid email address.');
        case 'user-disabled':
          throw AuthException('This user account has been disabled.');
        case 'too-many-requests':
          throw AuthException('Too many attempts. Try again later.');
        default:
          throw AuthException(e.message ?? 'Authentication error.');
      }
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } on FormatException catch (_) {/* ignore */}
    await _auth.signOut();
  }

  /// Google Sign-In using the v7 API (authenticate/attemptLightweightAuthentication).
  Future<UserCredential> signInWithGoogle() async {
    {
      try {
        if (kIsWeb) {
          final provider = GoogleAuthProvider();
          final cred = await _auth.signInWithPopup(provider);
          await _bootstrapUserAfterLogin(cred);
          return cred;
        }

        GoogleSignInAccount? account;

        // Try lightweight auth first, but don't crash on config issues.
        try {
          account = await GoogleSignIn.instance.attemptLightweightAuthentication();
        } on GoogleSignInException catch (_) {
          account = null; // fall back to interactive below
        }

        // Interactive auth (must be triggered from a user gesture)
        account ??= await GoogleSignIn.instance.authenticate();

        // Inside signInWithGoogle():
        final googleAuth =  account.authentication; // await it
        final firebaseCred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCred = await _auth.signInWithCredential(firebaseCred);

        await _bootstrapUserAfterLogin(userCred);
        return userCred;
      } on FirebaseAuthException catch (e) {
        throw AuthException(_mapFirebaseAuthError(e));
      } on GoogleSignInException catch (e) {
        throw AuthException(_mapGoogleSignInException(e));
      } on FormatException catch (e) {
        final text = e.toString().toLowerCase();
        final msg = text.contains('cancel') ? 'Sign-in was cancelled.' : 'Google Sign-In failed: $e';
        throw AuthException(msg);
      }
    }
  }

  /// Returns a GoogleSignInAccount if available **without** showing UI.
  /// Use this in build methods or initializers to avoid unexpected popups.
  Future<GoogleSignInAccount?> currentGoogleAccountNonInteractive() async {
    try {
      return await GoogleSignIn.instance.attemptLightweightAuthentication();
    } on GoogleSignInException catch (_) {
      return null;
    }
  }

  /// Silently fetches an access token for the current account, if any.
  /// Returns null if no account is available without UI.
  Future<String?> getAccessTokenSilently() async {
    final account = await currentGoogleAccountNonInteractive();
    if (account == null) return null;
    try {
      final auth = account.authentication;
      return auth.idToken;
    } on FormatException catch (_) {
      return null;
    }
  }

  /// Request Drive (drive.file) scope **only** on explicit user action.
  /// Set [interactive] to false to avoid any UI; this will simply return false.
  Future<bool> ensureDriveFileScope({bool interactive = true}) async {
    var account = await currentGoogleAccountNonInteractive();
    if (account == null && interactive) {
      try {
        account = await GoogleSignIn.instance.authenticate();
      } on GoogleSignInException catch (_) {
        return false;
      }
    }
    if (account == null) return false;

    if (!interactive) {
      // Avoid authorizing scopes silently as it may prompt; let callers decide when to show UI.
      return false;
    }

    try {
      await account.authorizationClient.authorizeScopes(
        const ['https://www.googleapis.com/auth/drive.file'],
      );
      return true;
    } on FormatException catch (_) {
      return false;
    }
  }

  /// Replacement for deprecated signInSilently(): v7 uses lightweight auth.
  Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    try {
      return await GoogleSignIn.instance.attemptLightweightAuthentication();
    } on GoogleSignInException catch (_) {
      return null;
    }
  }

  Future<void> _bootstrapUserAfterLogin(UserCredential userCredential) async {
    final uid = userCredential.user?.uid;
    if (uid == null) return;

    final googleAvatarUrl = userCredential.user?.photoURL ?? 'assets/default-avatar.webp';

    try {
      final doc = _firestore.collection('users').doc(uid);
      final snap = await doc.get();
      if (!snap.exists) {
        await doc.set({
          'workingHours': 7,
          'avatarUrl': userCredential.user?.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FormatException catch (_) {/* ignore connectivity errors */}

    final box = await _openBox();
    if (!box.containsKey(uid)) {
      await box.put(
        uid,
        UserSettings(
          userId: uid,
          avatarUrl: googleAvatarUrl,
          backup: false,
          askForBackup: false,
        ),
      );
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'Account exists with a different sign-in method.';
      default:
        return e.message ?? 'Authentication error.';
    }
  }

  String _mapGoogleSignInException(GoogleSignInException e) {
    final d = (e.description ?? '').toLowerCase();

    // Common v7 Android misconfig: serverClientId / OAuth console setup
    if (d.contains('developer console is not set up correctly')) {
      return 'Google Sign-In is misconfigured. Check that:\n'
          '- You passed the Web client ID as serverClientId to GoogleSignIn.initialize() on Android.\n'
          '- Your Android app is registered in Firebase with package name "lush.co.uk.ballistics_wallet_flutter" and correct SHA-1/SHA-256.\n'
          '- You downloaded the updated google-services.json after adding fingerprints.\n'
          '- The OAuth consent screen is configured (and your account is a test user if not published).\n'
          '- The Web client ID you use matches @string/default_web_client_id from this app.\n';
    }

    if (d.contains('cancel')) return 'Sign-in was cancelled.';
    if (d.contains('network') || d.contains('timeout')) return 'Network error. Please try again.';

    // Fallback to concise default
    return e.description?.isNotEmpty ?? false ? e.description! : 'Google Sign-In error.';
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
