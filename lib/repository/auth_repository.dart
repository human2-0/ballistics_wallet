import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChange => _auth.idTokenChanges();

  String get userEmailAddress => _auth.currentUser?.email ?? '';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException('User not found');
      } else if (e.code == 'wrong-password') {
        throw AuthException('Wrong password.');
      } else {
        throw AuthException('An error occurred. Please try again later.');
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final googleUser = await _googleSignIn.signIn();

    // Obtain the auth details from the request
    final googleAuth =
    await googleUser!.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final userCredential =
    await _auth.signInWithCredential(credential);

    // Checking if user data already exists
    final usersRef = _firestore.collection('users');
    final snapshot = await usersRef.doc(userCredential.user!.uid).get();

    if (!snapshot.exists) {
      // If the user data does not exist, create a new document
      await usersRef.doc(userCredential.user!.uid).set({
        'workingHours': 7, // Replace with actual working hours
        'avatarUrl': userCredential.user!.photoURL,
        // add more fields as needed
      });
    }

    return userCredential;
  }
}

class AuthException implements Exception {

  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
