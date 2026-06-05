import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInit;

  Stream<User?> get authStateChange => _auth.idTokenChanges();

  String get userEmailAddress => _auth.currentUser?.email ?? '';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> _ensureGoogleSignInInitialized() =>
      _googleSignInInit ??= _googleSignIn.initialize();

  Future<Box<UserSettings>> _openBox() =>
      Hive.openBox<UserSettings>('settings');

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // More specific error handling
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('User not found');
        case 'wrong-password':
          throw AuthException('Wrong password.');
        default:
          throw AuthException('An error occurred: ${e.message}');
      }
    }
  }

  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
    try {
      await _googleSignIn.disconnect();
    } on Object catch (_) {
      // ignore disconnect errors and proceed with Firebase sign-out
    }
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    try {
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const ['https://www.googleapis.com/auth/drive.file'],
      );

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final usersRef = _firestore.collection('users');
      final snapshot = await usersRef.doc(userCredential.user!.uid).get();

      final googleAvatarUrl =
          userCredential.user!.photoURL ??
          'assets/default-avatar.webp'; // Replace with a proper default avatar URL

      if (!snapshot.exists) {
        await usersRef.doc(userCredential.user!.uid).set({
          'workingHours': 7, // Replace with actual working hours
          'avatarUrl': userCredential.user!.photoURL,
          // Add more fields as needed
        });
        final box = await _openBox();

        await box.put(
          currentUserId,
          UserSettings(
            userId: currentUserId,
            avatarUrl: googleAvatarUrl,
            backup: false,
            askForBackup: false,
          ),
        );
      }

      final box = await _openBox();

      if (box.isEmpty) {
        await box.put(
          currentUserId,
          UserSettings(
            userId: currentUserId,
            avatarUrl: googleAvatarUrl,
            backup: false,
            askForBackup: false,
          ),
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      throw AuthException('Google sign-in failed: ${e.code}');
    } on FirebaseAuthException catch (e) {
      // Handling Firebase Auth exceptions
      throw AuthException('Firebase Auth Exception: ${e.message}');
    } on FormatException catch (e) {
      // Handling other exceptions
      throw AuthException('An unknown error occurred: $e');
    }
  }

  Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    await _ensureGoogleSignInInitialized();
    final future = _googleSignIn.attemptLightweightAuthentication();
    if (future == null) {
      return null;
    }
    return future;
  }

  Future<void> ensureDriveFileScope() async {
    await _ensureGoogleSignInInitialized();
    final googleUser = await getCurrentGoogleUser();
    if (googleUser == null) {
      await signInWithGoogle();
      return;
    }
    const scopes = ['https://www.googleapis.com/auth/drive.file'];
    final authz = await googleUser.authorizationClient.authorizationForScopes(
      scopes,
    );
    if (authz == null) {
      await googleUser.authorizationClient.authorizeScopes(scopes);
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
