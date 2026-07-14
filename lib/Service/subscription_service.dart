import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Single source of truth for the Plus subscription and the free-tier import
/// quota.
///
/// One boolean decides everything — `isPlus` (Free vs Plus). There are NO
/// tiers. Free users get [kFreeImportLimit] recipe imports from Image / Text /
/// Social; Website imports are unlimited and are never counted. State is
/// reactive (Rx) so any `Obx` reading it rebuilds when the plan or the count
/// changes, cached in GetStorage for instant/offline paint, and backed by the
/// `users/{uid}` document (`isPlus`, `recipeImportCount`).
///
/// This is the ONE place subscription logic lives — feature code only reads the
/// `canUse*()` gates (or wraps its UI in `PremiumLockOverlay`).
class SubscriptionService extends GetxController {
  /// Total lifetime imports a free user gets (Image + Text + Social).
  static const int kFreeImportLimit = 5;

  /// Convenience accessor — registers the singleton on first use.
  static SubscriptionService get instance =>
      Get.isRegistered<SubscriptionService>()
          ? Get.find<SubscriptionService>()
          : Get.put(SubscriptionService(), permanent: true);

  final _box = GetStorage();
  static const _kPlus = 'sub_is_plus';
  static const _kCount = 'sub_import_count';

  final RxBool _isPlus = false.obs;
  final RxInt _importCount = 0.obs;

  String? _uid;

  @override
  void onInit() {
    super.onInit();
    // Instant paint from cache (works offline / before auth resolves).
    _isPlus.value = _box.read(_kPlus) ?? false;
    _importCount.value = _box.read(_kCount) ?? 0;
  }

  DocumentReference<Map<String, dynamic>>? get _ref => _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid);

  /// Load the signed-in user's plan + import count. Safe to call after login.
  Future<void> bindUser(String uid) async {
    _uid = uid;
    try {
      final snap = await _ref!.get();
      final data = snap.data() ?? const {};
      final plus = data['isPlus'] == true;
      final count = (data['recipeImportCount'] as num?)?.toInt() ?? 0;
      _isPlus.value = plus;
      _importCount.value = count;
      _box.write(_kPlus, plus);
      _box.write(_kCount, count);
    } catch (_) {
      // Offline / permission error — keep cached values.
    }
  }

  void onLogout() => _uid = null;

  // ── Reactive reads ─────────────────────────────────────────────────────────

  bool get isPlus => _isPlus.value;
  int get recipeImportCount => _importCount.value;

  /// Exposed so widgets can react (e.g. `Obx(() => ... isPlusListenable ...)`).
  RxBool get isPlusListenable => _isPlus;
  RxInt get importCountListenable => _importCount;

  // ── Capability gates (the public API) ──────────────────────────────────────

  bool canUseRecipeImport() => isPlus || recipeImportCount < kFreeImportLimit;
  bool canUseNutrition() => isPlus;
  bool canUseCookingAssistant() => isPlus;
  bool canUseMealPlanner() => isPlus;
  bool canUseConverter() => isPlus;
  bool canExportPDF() => isPlus;
  bool canPrintRecipe() => isPlus;

  /// Remaining free imports (Image/Text/Social). Effectively unlimited for Plus.
  int remainingRecipeImports() => isPlus
      ? 999999
      : (kFreeImportLimit - recipeImportCount).clamp(0, kFreeImportLimit);

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Count one Image / Text / Social import (never Website). No-op for Plus.
  /// Called after a countable import successfully saves.
  Future<void> incrementImportCount() async {
    if (isPlus) return;
    final next = recipeImportCount + 1;
    _importCount.value = next;
    _box.write(_kCount, next);
    await _ref?.set(
      {'recipeImportCount': next},
      SetOptions(merge: true),
    );
  }

  /// Flip the plan (used by the upgrade flow / dev toggle) and persist it.
  /// Replace the body's caller with real billing entitlement when integrating a
  /// store — the rest of the app only reads [isPlus].
  Future<void> setPlus(bool value) async {
    _isPlus.value = value;
    _box.write(_kPlus, value);
    await _ref?.set({'isPlus': value}, SetOptions(merge: true));
  }
}
