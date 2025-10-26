import 'package:ballistics_wallet_flutter/models/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChange => _auth.idTokenChanges();

  String get userEmailAddress => _auth.currentUser?.email ?? '';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  Future<Box<UserSettings>> _openBox() {
    return Hive.openBox<UserSettings>('settings');
  }

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
    await _googleSignIn.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // ignore disconnect errors and proceed with Firebase sign-out
    }
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled by the user');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final usersRef = _firestore.collection('users');
      final snapshot = await usersRef.doc(userCredential.user!.uid).get();

      final googleAvatarUrl = userCredential.user!.photoURL ??
          'assets/default-avatar.webp'; // Replace with a proper default avatar URL



      if (!snapshot.exists) {
        await usersRef.doc(userCredential.user!.uid).set({
          'workingHours': 7, // Replace with actual working hours
          'avatarUrl': userCredential.user!.photoURL,
          // Add more fields as needed
        });
        final box = await _openBox();

        await box.put(
            currentUserId, UserSettings(userId: currentUserId,avatarUrl: googleAvatarUrl, backup: false, askForBackup: false),);
      }



      final box = await _openBox();

      if (box.isEmpty) {
        await box.put(
            currentUserId, UserSettings(userId: currentUserId, avatarUrl: googleAvatarUrl,backup: false, askForBackup: false),);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handling Firebase Auth exceptions
      throw AuthException('Firebase Auth Exception: ${e.message}');
    } on FormatException catch (e) {
      // Handling other exceptions
      throw AuthException('An unknown error occurred: $e');
    }
  }

  Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    return _googleSignIn.signInSilently();
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
