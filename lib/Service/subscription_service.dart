
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SubscriptionService extends GetxController {
  /// Maximum free imports available per week.
  static const int kWeeklyFreeCredits = 5;

  static SubscriptionService get instance =>
      Get.isRegistered<SubscriptionService>()
      ? Get.find<SubscriptionService>()
      : Get.put(SubscriptionService(), permanent: true);

  final _box = GetStorage();

  static const _kPlus = 'sub_is_plus';
  static const _kCredits = 'sub_free_credits';
  static const _kResetAt = 'sub_credits_reset_at';

  final RxBool _isPlus = false.obs;
  final RxInt _freeCredits = 0.obs;
  final Rxn<DateTime> _creditsResetAt = Rxn<DateTime>();

  String? _uid;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  @override
  void onInit() {
    super.onInit();

    _isPlus.value = _box.read(_kPlus) ?? false;

    _freeCredits.value = (_box.read(_kCredits) as num?)?.toInt() ?? 0;

    final cachedResetAt = _box.read(_kResetAt);

    if (cachedResetAt is String) {
      _creditsResetAt.value = DateTime.tryParse(cachedResetAt);
    }
  }

  DocumentReference<Map<String, dynamic>>? get _ref {
    if (_uid == null) return null;

    return FirebaseFirestore.instance.collection('users').doc(_uid);
  }

  // ============================================================
  // BIND USER
  // ============================================================

  Future<void> bindUser(String uid) async {
    _uid = uid;

    await _userSubscription?.cancel();

    final ref = _ref!;

    /*
     * IMPORTANT:
     *
     * First time user:
     *   freeCredits = 5
     *   creditsResetAt = next week
     *
     * Existing user:
     *   Keep current credits.
     *
     * If one week has passed:
     *   Reset credits to 5.
     */

    try {
      final snap = await ref.get();

      if (snap.exists) {
        final data = snap.data() ?? {};

        final isPlus = data['isPlus'] == true;

        _isPlus.value = isPlus;

        // --------------------------------------------------------
        // FIRST TIME / OLD USER WITHOUT CREDIT FIELD
        // --------------------------------------------------------

        if (!data.containsKey('freeCredits')) {
          final resetAt = _nextWeeklyReset();

          await ref.set({
            'freeCredits': kWeeklyFreeCredits,
            'creditsResetAt': Timestamp.fromDate(resetAt),
          }, SetOptions(merge: true));

          _freeCredits.value = kWeeklyFreeCredits;
          _creditsResetAt.value = resetAt;

          _cacheValues();

          print(
            '[Subscription] First-time credits initialized: '
            '$kWeeklyFreeCredits',
          );
        } else {
          final credits = (data['freeCredits'] as num?)?.toInt() ?? 0;

          final resetTimestamp = data['creditsResetAt'] as Timestamp?;

          DateTime? resetAt = resetTimestamp?.toDate();

          // ------------------------------------------------------
          // OLD USER WITHOUT resetAt
          // ------------------------------------------------------

          if (resetAt == null) {
            resetAt = _nextWeeklyReset();

            await ref.set({
              'creditsResetAt': Timestamp.fromDate(resetAt),
            }, SetOptions(merge: true));
          }

          // ------------------------------------------------------
          // WEEK EXPIRED
          // ------------------------------------------------------

          if (DateTime.now().isAfter(resetAt)) {
            resetAt = _nextWeeklyReset();

            await ref.set({
              'freeCredits': kWeeklyFreeCredits,
              'creditsResetAt': Timestamp.fromDate(resetAt),
            }, SetOptions(merge: true));

            _freeCredits.value = kWeeklyFreeCredits;
            _creditsResetAt.value = resetAt;

            print(
              '[Subscription] Weekly credits renewed: '
              '$kWeeklyFreeCredits',
            );
          } else {
            _freeCredits.value = credits;
            _creditsResetAt.value = resetAt;
          }

          _cacheValues();
        }
      } else {
        // --------------------------------------------------------
        // USER DOCUMENT DOES NOT EXIST
        // --------------------------------------------------------

        final resetAt = _nextWeeklyReset();

        await ref.set({
          'isPlus': false,
          'freeCredits': kWeeklyFreeCredits,
          'creditsResetAt': Timestamp.fromDate(resetAt),
        }, SetOptions(merge: true));

        _isPlus.value = false;
        _freeCredits.value = kWeeklyFreeCredits;
        _creditsResetAt.value = resetAt;

        _cacheValues();

        print(
          '[Subscription] New user created with '
          '$kWeeklyFreeCredits weekly credits',
        );
      }
    } catch (e) {
      print('[Subscription] bindUser error: $e');
    }

    // ------------------------------------------------------------
    // REAL-TIME LISTENER
    // ------------------------------------------------------------

    _userSubscription = ref.snapshots().listen((snap) async {
      if (!snap.exists) return;

      final data = snap.data() ?? {};

      final plus = data['isPlus'] == true;

      _isPlus.value = plus;

      final credits = (data['freeCredits'] as num?)?.toInt() ?? 0;

      final timestamp = data['creditsResetAt'] as Timestamp?;

      final resetAt = timestamp?.toDate();

      _freeCredits.value = credits;
      _creditsResetAt.value = resetAt;

      _cacheValues();
    });
  }

  // ============================================================
  // WEEKLY RESET DATE
  // ============================================================

  DateTime _nextWeeklyReset() {
    final now = DateTime.now();

    // 7 days from now.
    return now.add(const Duration(days: 7));
  }

  // ============================================================
  // CACHE
  // ============================================================

  void _cacheValues() {
    _box.write(_kPlus, _isPlus.value);
    _box.write(_kCredits, _freeCredits.value);

    final resetAt = _creditsResetAt.value;

    if (resetAt != null) {
      _box.write(_kResetAt, resetAt.toIso8601String());
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> onLogout() async {
    _uid = null;

    await _userSubscription?.cancel();

    _userSubscription = null;

    _isPlus.value = false;
    _freeCredits.value = 0;
    _creditsResetAt.value = null;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isPlus => _isPlus.value;

  int get freeCredits => _freeCredits.value;

  DateTime? get creditsResetAt => _creditsResetAt.value;

  RxBool get isPlusListenable => _isPlus;

  RxInt get freeCreditsListenable => _freeCredits;

  // ============================================================
  // CAPABILITY
  // ============================================================

  bool canUseRecipeImport() {
    return isPlus || freeCredits > 0;
  }

  bool canUseNutrition() => isPlus;

  bool canUseCookingAssistant() => isPlus;

  bool canUseMealPlanner() => isPlus;

  bool canUseConverter() => isPlus;

  bool canExportPDF() => isPlus;

  bool canPrintRecipe() => isPlus;

  int remainingRecipeImports() {
    return isPlus ? 999999 : freeCredits.clamp(0, kWeeklyFreeCredits);
  }

  // ============================================================
  // CONSUME CREDIT
  // ============================================================

  Future<bool> consumeCredit() async {
    if (isPlus) {
      return true;
    }

    final ref = _ref;

    if (ref == null) {
      return false;
    }

    try {
      final success = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final snap = await transaction.get(ref);

        if (!snap.exists) {
          return false;
        }

        final data = snap.data() ?? {};

        final currentCredits = (data['freeCredits'] as num?)?.toInt() ?? 0;

        final timestamp = data['creditsResetAt'] as Timestamp?;

        DateTime? resetAt = timestamp?.toDate();

        // ------------------------------------------------------
        // SAFETY:
        // If reset date is missing, initialize it.
        // ------------------------------------------------------

        if (resetAt == null) {
          resetAt = _nextWeeklyReset();

          transaction.update(ref, {
            'creditsResetAt': Timestamp.fromDate(resetAt),
          });
        }

        // ------------------------------------------------------
        // WEEK EXPIRED
        // ------------------------------------------------------

        if (DateTime.now().isAfter(resetAt)) {
          final newResetAt = _nextWeeklyReset();

          transaction.update(ref, {
            'freeCredits': kWeeklyFreeCredits - 1,
            'creditsResetAt': Timestamp.fromDate(newResetAt),
          });

          return true;
        }

        // ------------------------------------------------------
        // NO CREDIT
        // ------------------------------------------------------

        if (currentCredits <= 0) {
          return false;
        }

        // ------------------------------------------------------
        // CONSUME 1
        // ------------------------------------------------------

        transaction.update(ref, {'freeCredits': currentCredits - 1});

        return true;
      });

      if (success) {
        /*
         * Don't manually decrement here.
         *
         * Firestore snapshot listener will update the local
         * reactive value.
         */
        print('[Subscription] Credit consumed successfully');
      }

      return success;
    } catch (e) {
      print('[Subscription] consumeCredit error: $e');

      return false;
    }
  }

  // ============================================================
  // SET PLUS
  // ============================================================

  Future<void> setPlus(bool value) async {
    _isPlus.value = value;

    _box.write(_kPlus, value);

    await _ref?.set({'isPlus': value}, SetOptions(merge: true));
  }
}
