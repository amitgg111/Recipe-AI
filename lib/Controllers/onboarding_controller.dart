import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Holds every onboarding/intro selection so it survives:
///  * navigating back and forth (the flow recreates each step widget, which
///    would otherwise reset local state),
///  * app restarts (mirrored to [GetStorage] the instant a selection changes),
///  * and re-login / multi-device (synced to the user's Firestore document once
///    they authenticate — onboarding runs BEFORE auth, so there is no user doc
///    to write to until then).
///
/// Firestore is only ever the *existing* `users/{uid}` document with an
/// `onboarding` map merged in — never a duplicate document.
class OnboardingController extends GetxController {
  static OnboardingController get to => Get.find();

  final GetStorage _box = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSub;

  // ── Storage keys ───────────────────────────────────────────────────────────
  static const _kGoals = 'onb_goals';
  static const _kCuisines = 'onb_cuisines';
  static const _kWhenToCook = 'onb_when_to_cook';
  static const _kAttribution = 'onb_attribution';
  static const _kSources = 'onb_sources';
  static const _kAge = 'onb_age';
  static const _kNotifOptIn = 'onb_notif_opt_in';
  static const _kNotifGranted = 'onb_notif_granted';
  static const _kPending = 'onb_pending_sync';

  // ── Reactive selections (defaults match the original screens) ───────────────
  final RxSet<int> goals = <int>{0, 1}.obs; // multi-select
  final RxInt whenToCook = 0.obs; // single-select
  // Step 08 "How did you hear about us?" — multi-select attribution sources,
  // stored as an array of stable string keys. Empty by default so the Next
  // button stays disabled until the user picks at least one.
  final RxSet<String> attributionSources = <String>{}.obs;
  final RxSet<int> recipeSources = <int>{0}.obs; // multi-select
  final RxInt age = 1.obs; // single-select ("25-34")
  final RxSet<String> cuisines = <String>{}.obs; // ADD THIS — empty by default

  // Notifications step: [notificationsOptIn] = the user tapped "Allow" (vs
  // "Don't allow"); [notificationsGranted] = the OS actually authorised it.
  // Both null until the step is completed, so a returning user is distinguished
  // from one who has never made a choice.
  final RxnBool notificationsOptIn = RxnBool();
  final RxnBool notificationsGranted = RxnBool();

  @override
  void onInit() {
    super.onInit();
    _loadLocal();
    // Any successful auth (signup / login / Google / Apple) flips the user from
    // anonymous onboarding to a real account: push freshly-made selections, or
    // pull existing ones for a returning user on a new install.
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  // ── Local load / persist ────────────────────────────────────────────────────
  void _loadLocal() {
    final g = _box.read<List>(_kGoals);
    if (g != null) goals.assignAll(g.map((e) => e as int));
    final w = _box.read<int>(_kWhenToCook);
    if (w != null) whenToCook.value = w;
    final at = _box.read<List>(_kAttribution);
    if (at != null) attributionSources.assignAll(at.map((e) => e as String));
    final s = _box.read<List>(_kSources);
    if (s != null) recipeSources.assignAll(s.map((e) => e as int));
    final a = _box.read<int>(_kAge);
    if (a != null) age.value = a;
    final no = _box.read<bool>(_kNotifOptIn);
    final cu = _box.read<List>(_kCuisines); // ADD
    if (cu != null) cuisines.assignAll(cu.map((e) => e as String));
    if (no != null) notificationsOptIn.value = no;
    final ng = _box.read<bool>(_kNotifGranted);
    if (ng != null) notificationsGranted.value = ng;
  }

  // Setters persist to local storage immediately and mark data pending an
  // eventual Firebase sync. Writes are skipped when the value is unchanged to
  // avoid redundant work.
  void setGoals(Set<int> value) {
    if (setEquals(goals, value)) return;
    goals.assignAll(value);
    _box.write(_kGoals, value.toList());
    _markPending();
  }

  void setWhenToCook(int value) {
    if (whenToCook.value == value) return;
    whenToCook.value = value;
    _box.write(_kWhenToCook, value);
    _markPending();
  }

  void setAttributionSources(Set<String> value) {
    if (setEquals(attributionSources, value)) return;
    attributionSources.assignAll(value);
    _box.write(_kAttribution, value.toList());
    _markPending();
  }

  void setRecipeSources(Set<int> value) {
    if (setEquals(recipeSources, value)) return;
    recipeSources.assignAll(value);
    _box.write(_kSources, value.toList());
    _markPending();
  }

  void setAge(int value) {
    if (age.value == value) return;
    age.value = value;
    _box.write(_kAge, value);
    _markPending();
  }

  void setCuisines(Set<String> value) {
    if (setEquals(cuisines, value)) return;
    cuisines.assignAll(value);
    _box.write(_kCuisines, value.toList());
    _markPending();
  }

  /// Record the notifications-step choice. Persists locally immediately and
  /// (once authenticated) syncs to Firebase. Skips redundant writes so tapping
  /// the same choice twice never triggers a duplicate Firebase update.
  void setNotificationChoice({required bool optIn, required bool granted}) {
    if (notificationsOptIn.value == optIn &&
        notificationsGranted.value == granted) {
      return;
    }
    notificationsOptIn.value = optIn;
    notificationsGranted.value = granted;
    _box.write(_kNotifOptIn, optIn);
    _box.write(_kNotifGranted, granted);
    _markPending();
  }

  void _markPending() {
    _box.write(_kPending, true);
    // If the user is already authenticated (e.g. editing later), push right away.
    final uid = _auth.currentUser?.uid;
    if (uid != null) unawaited(syncToFirebase(uid));
  }

  // ── Firebase ────────────────────────────────────────────────────────────────
  Map<String, dynamic> _toMap() => {
    'goals': goals.toList()..sort(),
    'whenToCook': whenToCook.value,
    'attributionSources': attributionSources.toList()..sort(),
    'recipeSources': recipeSources.toList()..sort(),
    'age': age.value,
    'cuisines': cuisines.toList()..sort(), // ADD THIS
    // Only written once the notifications step is completed, so we never
    // clobber a real value with null on early syncs.
    if (notificationsOptIn.value != null)
      'notificationsOptIn': notificationsOptIn.value,
    if (notificationsGranted.value != null)
      'notificationsGranted': notificationsGranted.value,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  void _onAuthChanged(User? user) {
    if (user == null) return;
    final pending = _box.read<bool>(_kPending) ?? false;
    if (pending) {
      // Fresh selections from this onboarding session → push to Firebase.
      unawaited(syncToFirebase(user.uid));
    } else {
      // Returning user with no local changes → pull their saved selections.
      unawaited(loadFromFirebase(user.uid));
    }
  }

  /// Merge the current selections into the EXISTING user document (never
  /// creates a duplicate). Clears the pending flag on success; keeps it on
  /// failure so the next auth/selection change retries. Returns success.
  Future<bool> syncToFirebase(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'onboarding': _toMap(),
      }, SetOptions(merge: true));
      _box.write(_kPending, false);
      return true;
    } catch (_) {
      // Network / permission failure: local copy stays authoritative and the
      // pending flag remains set so we retry on the next opportunity.
      return false;
    }
  }

  /// Load previously-saved selections for a returning authenticated user and
  /// mirror them into local state (so the UI pre-selects them).
  Future<void> loadFromFirebase(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final onb = snap.data()?['onboarding'] as Map<String, dynamic>?;
      if (onb == null) return;

      if (onb['goals'] is List) {
        goals.assignAll((onb['goals'] as List).map((e) => e as int));
        _box.write(_kGoals, goals.toList());
      }
      if (onb['whenToCook'] is int) {
        whenToCook.value = onb['whenToCook'] as int;
        _box.write(_kWhenToCook, whenToCook.value);
      }
      if (onb['attributionSources'] is List) {
        attributionSources.assignAll(
          (onb['attributionSources'] as List).map((e) => e as String),
        );
        _box.write(_kAttribution, attributionSources.toList());
      }
      if (onb['recipeSources'] is List) {
        recipeSources.assignAll(
          (onb['recipeSources'] as List).map((e) => e as int),
        );
        _box.write(_kSources, recipeSources.toList());
      }
      if (onb['age'] is int) {
        age.value = onb['age'] as int;
        _box.write(_kAge, age.value);
      }
      if (onb['notificationsOptIn'] is bool) {
        notificationsOptIn.value = onb['notificationsOptIn'] as bool;
        _box.write(_kNotifOptIn, notificationsOptIn.value);
      }
      if (onb['cuisines'] is List) {
        // ADD
        cuisines.assignAll(
          (onb['cuisines'] as List).map((e) => e as String),
        ); // ADD
        _box.write(_kCuisines, cuisines.toList()); // ADD
      }
      if (onb['notificationsGranted'] is bool) {
        notificationsGranted.value = onb['notificationsGranted'] as bool;
        _box.write(_kNotifGranted, notificationsGranted.value);
      }
      _box.write(_kPending, false);
    } catch (_) {
      // Ignore — local defaults remain in place.
    }
  }
}
