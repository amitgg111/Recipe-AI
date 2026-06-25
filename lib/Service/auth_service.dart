import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ====================================================
  // Current User
  // ====================================================

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ====================================================
  // Sign Up
  // ====================================================

  static Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user?.updateDisplayName(name);

    await _firestore.collection("users").doc(credential.user!.uid).set({
      "uid": credential.user!.uid,
      "name": name,
      "email": email,
      "photoUrl": "",
      "provider": "email",
      "createdAt": FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // ====================================================
  // Login
  // ====================================================

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ====================================================
  // Google Sign In
  // ====================================================

  // static Future<UserCredential?> signInWithGoogle() async {
  //   final GoogleSignIn googleSignIn = GoogleSignIn();

  //   await googleSignIn.signOut();

  //   final GoogleSignInAccount? account = await googleSignIn.signIn();

  //   if (account == null) return null;

  //   final GoogleSignInAuthentication auth = await account.authentication;

  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: auth.accessToken,
  //     idToken: auth.idToken,
  //   );

  //   final userCredential = await _auth.signInWithCredential(credential);

  //   final user = userCredential.user!;

  //   final doc = _firestore.collection("users").doc(user.uid);

  //   // ALWAYS sync latest Google data
  //   await doc.set({
  //     "uid": user.uid,
  //     "name": user.displayName ?? "",
  //     "email": user.email ?? "",
  //     "photoUrl": user.photoURL ?? "",
  //     "provider": "google",
  //     "updatedAt": FieldValue.serverTimestamp(),
  //   }, SetOptions(merge: true));

  //   // IMPORTANT: force refresh FirebaseAuth user
  //   await user.reload();

  //   return userCredential;
  // }

  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'], // IMPORTANT
    );

    await googleSignIn.signOut();

    final GoogleSignInAccount? account = await googleSignIn.signIn();

    if (account == null) return null;

    final GoogleSignInAuthentication auth = await account.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    final user = userCredential.user!;

    // 🔥 IMPORTANT: FORCE REFRESH
    await user.reload();
    final freshUser = FirebaseAuth.instance.currentUser;

    final photo = freshUser?.photoURL ?? account.photoUrl ?? "";

    final doc = _firestore.collection("users").doc(user.uid);

    await doc.set({
      "uid": user.uid,
      "name": user.displayName ?? account.displayName ?? "",
      "email": user.email ?? account.email,
      "photoUrl": photo,
      "provider": "google",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return userCredential;
  }

  // ====================================================
  // Forgot Password
  // ====================================================

  static Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ====================================================
  // Logout
  // ====================================================

  // static Future<void> logout() async {
  //   await GoogleSignIn().signOut();
  //   await _auth.signOut();
  // }
  static Future<void> logout() async {
    await GoogleSignIn().disconnect(); // IMPORTANT
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
