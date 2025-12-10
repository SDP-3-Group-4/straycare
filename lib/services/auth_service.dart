import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../features/profile/repositories/user_repository.dart';

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
  Future<void> setPersistence(bool isLocal) async {
    try {
      if (kIsWeb) {
        await _auth.setPersistence(
          isLocal ? Persistence.LOCAL : Persistence.SESSION,
        );
      } else {
        // On mobile, session persistence isn't directly supported in the same way
        // as web for "closing the app". FirebaseAuth mobile SDKs persist by default.
        // However, we can simulate "SESSION" by not auto-logging in if a flag is set,
        // or just rely on the user explicitly logging out.
        //
        // Note: The FlutterFire plugin documentation states setPersistence is web only
        // for "Session" vs "Local". On mobile it is always "Local".
        // To support "Don't Remember Me" on mobile, we would typically need to
        // sign out the user when the app lifecycle state changes (closes).
        //
        // For this implementation, we will apply it where supported (Web) and
        // for mobile we might need a different strategy if strict "session" is needed.
        // But the user request implies they want "Remember Me" to *enable* persistence
        // so we can assume the default is persistent, and "unchecked" might need
        // explicit handling.
        //
        // Actually, a better approach for mobile "Don't remember me" is to simple
        // not restore the session in main.dart if a local preference says so.
      }
    } catch (e) {
      print("Error setting persistence: $e");
    }
  }

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

      // Save user to Firestore
      if (cred.user != null) {
        await UserRepository().saveUser(cred.user!.uid, {
          'email': email.trim(),
          'displayName': displayName ?? 'User',
          'photoUrl': '',
          'bio': 'No bio available',
          'createdAt': FieldValue.serverTimestamp(),
        });
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
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Sync user data to ensure valid profile and verifiedStatus
      if (userCredential.user != null) {
        await UserRepository().saveUser(userCredential.user!.uid, {
          'email': email.trim(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
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

      // Save user to Firestore
      if (userCredential.user != null) {
        final userDoc = await UserRepository().getUser(
          userCredential.user!.uid,
        );

        if (!userDoc.exists) {
          // New user: Create with default bio
          await UserRepository().saveUser(userCredential.user!.uid, {
            'email': googleUser.email,
            'displayName': googleUser.displayName ?? 'User',
            'photoUrl': googleUser.photoUrl ?? '',
            'bio': 'No bio available',
            'lastLogin': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user: Update only necessary fields, preserve bio
          // Use saveUser to ensure verifiedStatus checks are applied
          await UserRepository().saveUser(userCredential.user!.uid, {
            'email': googleUser.email,
            'displayName': googleUser.displayName ?? 'User',
            'photoUrl': googleUser.photoUrl ?? '',
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
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
