import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._firebaseAuth) {
    _authSubscription = _firebaseAuth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  final FirebaseAuth _firebaseAuth;
  late final StreamSubscription<User?> _authSubscription;

  User? get currentUser => _firebaseAuth.currentUser;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      await _firebaseAuth.signInWithPopup(googleProvider);
      return;
    }

    final googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Google sign-in was cancelled.',
      );
    }

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }
}
