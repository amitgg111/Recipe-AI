import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Single source of truth for the Plus subscription and the free-tier credits.
///
/// State is reactive (Rx) so any `Obx` reading it rebuilds when the plan or the count
/// changes, cached in GetStorage for instant/offline paint, and backed by the
/// `users/{uid}` document (`isPlus`, `freeCredits`).
///
/// This is the ONE place subscription logic lives — feature code only reads the
/// `canUse*()` gates (or wraps its UI in `PremiumLockOverlay`).
class SubscriptionService extends GetxController {
  /// Total lifetime credits a free user gets.
  static const int kInitialFreeCredits = 5;

  /// Convenience accessor — registers the singleton on first use.
  static SubscriptionService get instance =>
      Get.isRegistered<SubscriptionService>()
      ? Get.find<SubscriptionService>()
      : Get.put(SubscriptionService(), permanent: true);

  final _box = GetStorage();
  static const _kPlus = 'sub_is_plus';
  static const _kCredits = 'sub_free_credits';

  final RxBool _isPlus = false.obs;
  final RxInt _freeCredits = 0.obs;

  String? _uid;

  @override
  void onInit() {
    super.onInit();
    // Instant paint from cache (works offline / before auth resolves).
    _isPlus.value = _box.read(_kPlus) ?? false;
    _freeCredits.value = _box.read(_kCredits) ?? 0;
  }

  DocumentReference<Map<String, dynamic>>? get _ref => _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  /// Load the signed-in user's plan + credit count. Safe to call after login.
  Future<void> bindUser(String uid) async {
    _uid = uid;

    await _userSubscription?.cancel();

    _userSubscription = _ref!.snapshots().listen((snap) {
      final data = snap.data() ?? const {};

      final plus = data['isPlus'] == true;

      final credits =
          (data['freeCredits'] as num?)?.toInt() ?? kInitialFreeCredits;

      _isPlus.value = plus;
      _freeCredits.value = credits;

      _box.write(_kPlus, plus);
      _box.write(_kCredits, credits);
    });
  }
  // Future<void> bindUser(String uid) async {
  //   _uid = uid;
  //   try {
  //     final snap = await _ref!.get();
  //     final data = snap.data() ?? const {};
  //     final plus = data['isPlus'] == true;
  //     // If user doesn't have freeCredits yet (e.g. old user), default to 5
  //     final credits = (data['freeCredits'] as num?)?.toInt() ?? kInitialFreeCredits;
  //     _isPlus.value = plus;
  //     _freeCredits.value = credits;
  //     _box.write(_kPlus, plus);
  //     _box.write(_kCredits, credits);
  //   } catch (_) {
  //     // Offline / permission error — keep cached values.
  //   }
  // }

  void onLogout() {
    _uid = null;
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  // ── Reactive reads ─────────────────────────────────────────────────────────

  bool get isPlus => _isPlus.value;
  int get freeCredits => _freeCredits.value;

  /// Exposed so widgets can react (e.g. `Obx(() => ... isPlusListenable ...)`).
  RxBool get isPlusListenable => _isPlus;
  RxInt get freeCreditsListenable => _freeCredits;

  // ── Capability gates (the public API) ──────────────────────────────────────

  bool canUseRecipeImport() => isPlus || freeCredits > 0;
  bool canUseNutrition() => isPlus;
  bool canUseCookingAssistant() => isPlus;
  bool canUseMealPlanner() => isPlus;
  bool canUseConverter() => isPlus;
  bool canExportPDF() => isPlus;
  bool canPrintRecipe() => isPlus;

  /// Remaining free imports. Effectively unlimited for Plus.
  int remainingRecipeImports() =>
      isPlus ? 999999 : freeCredits.clamp(0, kInitialFreeCredits);

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Atomically consume 1 credit if the user is free.
  /// Uses a Firestore transaction to prevent race conditions and negative credits.
  /// Called ONLY when the feature usage is successfully authorized.
  /// Returns true if successful (or if Plus), false if insufficient credits or network error.
  Future<bool> consumeCredit() async {
    if (isPlus) return true;
    if (_ref == null) return false;

    try {
      final success = await FirebaseFirestore.instance.runTransaction((
        transaction,
      ) async {
        final snap = await transaction.get(_ref!);
        if (!snap.exists) return false;

        final data = snap.data() ?? {};
        final currentCredits =
            (data['freeCredits'] as num?)?.toInt() ?? kInitialFreeCredits;

        if (currentCredits <= 0) {
          return false;
        }

        final next = currentCredits - 1;
        transaction.update(_ref!, {'freeCredits': next});
        return true;
      });

      if (success) {
        _freeCredits.value -= 1;
        _box.write(_kCredits, _freeCredits.value);
      }
      return success;
    } catch (_) {
      // e.g. transaction failed due to network
      return false;
    }
  }

  /// Flip the plan (used by the upgrade flow / dev toggle) and persist it.
  Future<void> setPlus(bool value) async {
    _isPlus.value = value;
    _box.write(_kPlus, value);
    await _ref?.set({'isPlus': value}, SetOptions(merge: true));
  }
}
