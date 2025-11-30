import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// AuthService handles all authentication‑related operations.
///
/// Features:
///  - Email/Password sign‑up & sign‑in
///  - Google Sign‑In (mobile & web)
///  - Sign‑out (including Google)
///  - Password reset
///  - User profile helpers (display name, photo, email verification)
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? _firebaseAuth;
  FirebaseAuth get _auth {
    _firebaseAuth ??= FirebaseAuth.instance;
    return _firebaseAuth!;
  }

  // ---------------------------------------------------------------------
  // Google Sign‑In helper – uses a clientId on the web.
  // ---------------------------------------------------------------------
  GoogleSignIn _getGoogleSignIn() {
    if (kIsWeb) {
      return GoogleSignIn(
        clientId:
            '167700736671-c3n8piqj237k3kvj1e22gl7okcupj1fg.apps.googleusercontent.com',
      );
    }
    return GoogleSignIn();
  }

  // ---------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName.trim());
      }
      return cred;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Google Sign‑In (web & mobile)
  // ---------------------------------------------------------------------
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In...');
      final googleSignIn = _getGoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In cancelled by user.');
        return null;
      }
      print('Google User obtained: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print(
        'Google Auth obtained. AccessToken: ${googleAuth.accessToken != null}, IdToken: ${googleAuth.idToken != null}',
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('Firebase Sign In successful: ${userCredential.user?.uid}');

      // Propagate Google profile info to Firebase user record
      if (googleUser.displayName != null) {
        await userCredential.user?.updateDisplayName(googleUser.displayName!);
        print('Updated display name: ${googleUser.displayName}');
      }
      if (googleUser.photoUrl != null) {
        await userCredential.user?.updatePhotoURL(googleUser.photoUrl!);
        print('Updated photo URL: ${googleUser.photoUrl}');
      }

      return userCredential;
    } catch (e) {
      print('Google Sign In Error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Sign out (Firebase + Google)
  // ---------------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      try {
        final googleSignIn = _getGoogleSignIn();
        await googleSignIn.signOut();
      } catch (e) {
        // Ignore Google sign‑out errors – they are non‑critical
        print('Google sign out error: $e');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Account management helpers
  // ---------------------------------------------------------------------
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      await signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  bool isEmailVerified() => _auth.currentUser?.emailVerified ?? false;

  // ---------------------------------------------------------------------
  // Simple getters for UI consumption
  // ---------------------------------------------------------------------
  String getUserDisplayName() => _auth.currentUser?.displayName ?? '';
  String getUserEmail() => _auth.currentUser?.email ?? '';
  String getUserUid() => _auth.currentUser?.uid ?? '';
}
