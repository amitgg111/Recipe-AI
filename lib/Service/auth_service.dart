import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/local_notification_service.dart';
import 'package:recipe_ai/Service/notification_service.dart';
import 'package:recipe_ai/Service/revenuecat_service.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';
import 'package:recipe_ai/Service/analytics_service.dart';
import 'package:recipe_ai/utils/auth_error_mapper.dart';

/// Outcome of an Apple Sign In attempt.
///
/// A single, explicit result type keeps the UI layer free of provider-specific
/// exception handling: callers just branch on [success] / [cancelled] and read
/// [errorMessage]. It never throws, so screens can `await` it inside a simple
/// try/finally that only manages the loading spinner.
class AppleSignInResult {
  /// Whether Firebase authentication completed successfully.
  final bool success;

  /// Whether the user deliberately dismissed the Apple sheet. This is NOT an
  /// error — the UI should stay silent (no red snackbar) in this case.
  final bool cancelled;

  /// The authenticated Firebase user (only present when [success] is true).
  final User? user;

  /// True the first time this Apple ID authenticates with the Firebase project.
  final bool isNewUser;

  /// Machine-readable error code (e.g. Firebase code, `network`, `unknown`).
  final String? errorCode;

  /// Human-readable error message suitable for display.
  final String? errorMessage;

  const AppleSignInResult._({
    required this.success,
    this.cancelled = false,
    this.user,
    this.isNewUser = false,
    this.errorCode,
    this.errorMessage,
  });

  factory AppleSignInResult.success(User user, {bool isNewUser = false}) =>
      AppleSignInResult._(success: true, user: user, isNewUser: isNewUser);

  factory AppleSignInResult.cancelled() =>
      const AppleSignInResult._(success: false, cancelled: true);

  factory AppleSignInResult.failure(String code, String? message) =>
      AppleSignInResult._(
        success: false,
        errorCode: code,
        errorMessage: message ?? 'Something went wrong. Please try again.',
      );
}

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
    // Defensive trim at the service boundary (never trust the caller).
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    await credential.user?.updateDisplayName(trimmedName);

    // merge:true so this never clobbers the `onboarding` map that
    // OnboardingController writes to the same doc on this auth event.
    final initialResetAt = DateTime.now().add(const Duration(days: 7));

    await _firestore.collection("users").doc(credential.user!.uid).set({
      "uid": credential.user!.uid,
      "name": trimmedName,
      "email": trimmedEmail,
      "photoUrl": "",
      "provider": "email",
      "trialChooserCompleted": false,

      // Weekly free credits
      "freeCredits": RemoteConfigService.instance.newUserCredit,
      "creditsResetAt": Timestamp.fromDate(initialResetAt),

      "createdAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Guarantee the onboarding selections land in Firebase for this new
    // account, regardless of the auth-listener timing.
    if (Get.isRegistered<OnboardingController>()) {
      await OnboardingController.to.syncToFirebase(credential.user!.uid);
    }

    await AnalyticsService.instance.setUserId(credential.user!.uid);
    await AnalyticsService.instance.trackSignUp('email');

    return credential;
  }

  // ====================================================
  // Login
  // ====================================================

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (credential.user != null) {
      await AnalyticsService.instance.setUserId(credential.user!.uid);
      await AnalyticsService.instance.trackLogin('email');
    }
    return credential;
  }

  // ====================================================
  // Google Sign In
  // ====================================================

  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
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

    await user.reload();
    final freshUser = FirebaseAuth.instance.currentUser;

    final photo = freshUser?.photoURL ?? account.photoUrl ?? "";

    final email = user.email ?? account.email;
    final googleName = (user.displayName?.trim().isNotEmpty == true)
        ? user.displayName!.trim()
        : email.split('@').first;

    // Update Firebase Auth display name
    await user.updateDisplayName(googleName);

    final doc = _firestore.collection("users").doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      final initialResetAt = DateTime.now().add(const Duration(days: 7));

      await doc.set({
        "uid": user.uid,
        "name": googleName,
        "email": email,
        "photoUrl": photo,
        "provider": "google",
        "trialChooserCompleted": false,

        // Weekly free credits
        "freeCredits": RemoteConfigService.instance.newUserCredit,
        "creditsResetAt": Timestamp.fromDate(initialResetAt),

        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (Get.isRegistered<OnboardingController>()) {
        await OnboardingController.to.syncToFirebase(user.uid);
      }
    } else {
      await doc.set({
        "name": googleName,
        "email": email,
        "photoUrl": photo,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await AnalyticsService.instance.setUserId(user.uid);
    await AnalyticsService.instance.trackLogin('google');

    return userCredential;
  }

  // ====================================================
  // Apple Sign In
  // ====================================================

  /// Signs the user in with Apple and authenticates them against Firebase.
  ///
  /// Flow:
  ///  1. Generate a cryptographically-secure raw nonce and its SHA-256 hash.
  ///     Apple receives the *hashed* nonce inside the identity token; Firebase
  ///     is given the *raw* nonce and verifies the two match. This binds the
  ///     token to this specific request and defends against replay attacks.
  ///  2. Present the native Apple authorization sheet.
  ///  3. Exchange Apple's identity token for a Firebase [OAuthCredential] and
  ///     sign in.
  ///  4. Persist the profile in Firestore (create if new, otherwise fill only
  ///     missing fields — existing data is never clobbered).
  ///
  /// Existing providers (Google / email) are untouched. This method never
  /// throws: every failure mode is mapped to an [AppleSignInResult].
  static Future<AppleSignInResult> signInWithApple() async {
    try {
      // Apple Sign In is only available on iOS 13+/macOS 10.15+. On any other
      // platform (or older OS) fail gracefully instead of crashing.
      if (!await SignInWithApple.isAvailable()) {
        return AppleSignInResult.failure(
          'unavailable',
          'Apple Sign In is not available on this device.',
        );
      }

      // 1. Nonce: raw value kept for Firebase, SHA-256 hash sent to Apple.
      final String rawNonce = _generateNonce();
      final String hashedNonce = _sha256OfString(rawNonce);

      // 2. Request the Apple credential (opens the native system sheet).
      //    Name + email are only returned on the *first* authorization for
      //    this Apple ID, so we capture them here to seed the Firestore doc.
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
            scopes: const [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce,
          );

      // 3. Build the Firebase OAuth credential with the RAW nonce.
      final OAuthCredential oauthCredential = OAuthProvider('apple.com')
          .credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
            accessToken: appleCredential.authorizationCode,
          );

      // Sign in / link to Firebase.
      final UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );
      final User user = userCredential.user!;
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // Compose a display name from Apple's given/family name parts.
      final String fullName = [
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].where((p) => p.isNotEmpty).join(' ').trim();

      // Seed the Firebase Auth displayName only when it is currently empty so
      // we don't overwrite a name the user set elsewhere (Apple omits the name
      // on every sign-in after the first).
      if (fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
      }

      // 4. Persist to Firestore without clobbering existing data.
      await _syncAppleUser(
        user,
        appleFullName: fullName,
        appleEmail: appleCredential.email,
      );

      await AnalyticsService.instance.setUserId(user.uid);
      if (isNewUser) {
        await AnalyticsService.instance.trackSignUp('apple');
      } else {
        await AnalyticsService.instance.trackLogin('apple');
      }

      return AppleSignInResult.success(user, isNewUser: isNewUser);
    } on SignInWithAppleAuthorizationException catch (e) {
      // User dismissed the sheet → treat as a silent cancellation.
      if (e.code == AuthorizationErrorCode.canceled) {
        return AppleSignInResult.cancelled();
      }
      return AppleSignInResult.failure(
        e.code.name,
        'Apple sign-in could not be completed. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      // Firebase-side failures (invalid credential, disabled account, an
      // existing account with a different provider, etc.) — mapped to a
      // friendly, consistent message.
      return AppleSignInResult.failure(e.code, AuthErrorMapper.message(e));
    } on SocketException {
      // No connectivity.
      return AppleSignInResult.failure(
        'network',
        'No internet connection. Please check your network and try again.',
      );
    } catch (e) {
      // Any unexpected error — never surface the raw exception to the user.
      return AppleSignInResult.failure(
        'unknown',
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Creates the Firestore user document on first sign-in, or fills in only the
  /// fields that are still missing for a returning user. Existing values are
  /// never overwritten — Apple stops sending name/email after the first login,
  /// so blindly merging would wipe good data with blanks.
  static Future<void> _syncAppleUser(
    User user, {
    required String appleFullName,
    String? appleEmail,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('users')
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();

    if (!snapshot.exists) {
      // First-time user → create the full profile document. merge:true so it
      // never clobbers the `onboarding` map written on the same auth event.
      await ref.set({
        'uid': user.uid,
        'name': appleFullName.isNotEmpty
            ? appleFullName
            : (user.displayName ?? ''),
        'email': appleEmail ?? user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': 'apple',
        'trialChooserCompleted': false,
        'freeCredits': RemoteConfigService.instance.newUserCredit,
        'creditsResetAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (Get.isRegistered<OnboardingController>()) {
        await OnboardingController.to.syncToFirebase(user.uid);
      }
      return;
    }

    // Returning user → only patch fields that are currently empty/missing.
    final Map<String, dynamic> data = snapshot.data() ?? {};
    final Map<String, dynamic> updates = {};

    final String? existingName = data['name'] as String?;
    if ((existingName == null || existingName.isEmpty) &&
        appleFullName.isNotEmpty) {
      updates['name'] = appleFullName;
    }

    final String? existingEmail = data['email'] as String?;
    final String? incomingEmail = appleEmail ?? user.email;
    if ((existingEmail == null || existingEmail.isEmpty) &&
        (incomingEmail != null && incomingEmail.isNotEmpty)) {
      updates['email'] = incomingEmail;
    }

    // Only touch Firestore if there is genuinely something new to write.
    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(updates, SetOptions(merge: true));
    }
  }

  /// Returns a random alphanumeric string used as the OAuth nonce.
  static String _generateNonce([int length = 32]) {
    const String charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Returns the hex-encoded SHA-256 hash of [input].
  static String _sha256OfString(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ====================================================
  // Forgot Password
  // ====================================================

  static Future<void> forgotPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Whether [email] already has an account. Uses a server-side Cloud Function
  /// (Admin SDK `getUserByEmail`) so it works even when Firebase email
  /// enumeration protection is enabled — the client-only APIs hide existence in
  /// that case. Falls back to `true` (do not block) if the function is
  /// unavailable / not deployed.
  static Future<bool> isEmailRegistered(String email) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'checkEmailRegistered',
      );
      final res = await callable.call({'email': email.trim()});
      final data = res.data;
      if (data is Map && data['registered'] is bool) {
        return data['registered'] as bool;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // ====================================================
  // Logout
  // ====================================================

  static Future<void> logout() async {
    // Google disconnect/sign-out throws when the current session isn't a
    // Google one (email / Apple sign-in). Guard it so it can NEVER block the
    // Firebase sign-out below — otherwise "Log out" silently does nothing.
    try {
      final google = GoogleSignIn();
      if (await google.isSignedIn()) {
        await google.disconnect();
      }
      await google.signOut();
    } catch (_) {}
    await AnalyticsService.instance.clearUserId();
    await _auth.signOut();
  }

  /// Permanently deletes the current account and clears local app state.
  static Future<void> deleteAccountEverywhere() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    await _deleteFirestoreData(uid);

    await _deleteStorageData(uid);
    await _deleteAuthUser(user);
    await _clearLocalAppData();
    await logout();
  }

  static Future<void> _deleteFirestoreData(String uid) async {
    Future<void> safe(Future<void> Function() action, String label) async {
      try {
        await action();
        print('$label deleted');
      } catch (e) {
        print('$label delete FAILED: $e');
        // swallow so it never blocks the rest of the deletion flow
      }
    }

    await safe(
      () => _deleteDocuments(
        _firestore.collection('users').doc(uid).collection('followers'),
      ),
      'followers',
    );

    await safe(
      () => _deleteDocuments(
        _firestore.collection('users').doc(uid).collection('following'),
      ),
      'following',
    );

    await safe(
      () => _deleteDocuments(
        _firestore.collection('users').doc(uid).collection('groceries'),
      ),
      'groceries',
    );

    await safe(
      () => _deleteDocuments(
        _firestore.collection('users').doc(uid).collection('meal_plans'),
      ),
      'meal_plans',
    );

    await safe(() async {
      final draftRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('meal_planner_draft')
          .doc('current');
      await draftRef.delete();
    }, 'meal_planner_draft');

    await safe(() async {
      final ownedRecipes = await _firestore
          .collection('recipes')
          .where('ownerId', isEqualTo: uid)
          .get();
      for (final recipe in ownedRecipes.docs) {
        await safe(
          () => _deleteDocuments(recipe.reference.collection('likes')),
          'recipe likes',
        );
        await safe(
          () => _deleteDocuments(recipe.reference.collection('saves')),
          'recipe saves',
        );
        await safe(
          () => _deleteDocuments(recipe.reference.collection('comments')),
          'recipe comments',
        );
        await safe(
          () => _deleteDocuments(recipe.reference.collection('ratings')),
          'recipe ratings',
        );
        await safe(() => recipe.reference.delete(), 'recipe doc');
      }
    }, 'owned recipes');

    await safe(() async {
      final notifications = await _firestore
          .collection('notifications')
          .where('senderUserId', isEqualTo: uid)
          .get();

      final received = await _firestore
          .collection('notifications')
          .where('receiverUserId', isEqualTo: uid)
          .get();

      final notifIds = <String>{};
      for (final d in [...notifications.docs, ...received.docs]) {
        notifIds.add(d.id);
      }
      if (notifIds.isNotEmpty) {
        final batch = _firestore.batch();
        for (final id in notifIds) {
          batch.delete(_firestore.collection('notifications').doc(id));
        }
        await batch.commit();
      }
    }, 'notifications');

    // ✅ Guaranteed last step — runs even if everything above failed.
    await safe(
      () => _firestore.collection('users').doc(uid).delete(),
      'user root doc',
    );
  }

  static Future<void> _deleteDocuments(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snap = await col.limit(500).get();
      if (snap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  static Future<void> _deleteStorageData(String uid) async {
    await _deleteStoragePrefix(FirebaseStorage.instance.ref('users/$uid'));
  }

  static Future<void> _deleteStoragePrefix(Reference ref) async {
    try {
      final list = await ref.listAll();
      for (final item in list.items) {
        await item.delete();
      }
      for (final prefix in list.prefixes) {
        await _deleteStoragePrefix(prefix);
      }
    } catch (_) {}
  }

  static Future<void> _deleteAuthUser(User user) async {
    try {
      await user.delete();
      print('user');
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
    }
  }

  static Future<void> _clearLocalAppData() async {
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clearLocalData();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<SettingsController>()) {
        await Get.find<SettingsController>().onLogout();
      }
    } catch (_) {}

    try {
      SubscriptionService.instance.onLogout();
    } catch (_) {}

    try {
      await NotificationService.instance.logoutUser();
    } catch (_) {}

    try {
      await LocalNotificationService.instance.cancelMealPlanReminder();
      await LocalNotificationService.instance.cancelWeeklyGroceryReminder();
      await LocalNotificationService.instance.cancelAllCookTimerAlerts();
      await LocalNotificationService.instance.cancelTrialEndReminder();
    } catch (_) {}

    try {
      await RevenueCatService.instance.logoutUser();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}

    try {
      GetStorage().erase();
    } catch (_) {}
  }
}
