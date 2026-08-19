// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';

// class SubscriptionService extends GetxController {
//   /// Maximum free imports available per week.
//   static const int kWeeklyFreeCredits = 5;

//   static SubscriptionService get instance =>
//       Get.isRegistered<SubscriptionService>()
//       ? Get.find<SubscriptionService>()
//       : Get.put(SubscriptionService(), permanent: true);

//   final _box = GetStorage();

//   static const _kPlus = 'sub_is_plus';
//   static const _kCredits = 'sub_free_credits';
//   static const _kResetAt = 'sub_credits_reset_at';

//   final RxBool _isPlus = false.obs;
//   final RxInt _freeCredits = 0.obs;
//   final Rxn<DateTime> _creditsResetAt = Rxn<DateTime>();

//   String? _uid;

//   StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

//   @override
//   void onInit() {
//     super.onInit();

//     _isPlus.value = _box.read(_kPlus) ?? false;

//     _freeCredits.value = (_box.read(_kCredits) as num?)?.toInt() ?? 0;

//     final cachedResetAt = _box.read(_kResetAt);

//     if (cachedResetAt is String) {
//       _creditsResetAt.value = DateTime.tryParse(cachedResetAt);
//     }
//   }

//   DocumentReference<Map<String, dynamic>>? get _ref {
//     if (_uid == null) return null;

//     return FirebaseFirestore.instance.collection('users').doc(_uid);
//   }

//   // ============================================================
//   // BIND USER
//   // ============================================================

//   Future<void> bindUser(String uid) async {
//     _uid = uid;

//     await _userSubscription?.cancel();

//     final ref = _ref!;

//     /*
//      * IMPORTANT:
//      *
//      * First time user:
//      *   freeCredits = 5
//      *   creditsResetAt = next week
//      *
//      * Existing user:
//      *   Keep current credits.
//      *
//      * If one week has passed:
//      *   Reset credits to 5.
//      */

//     try {
//       final snap = await ref.get();

//       if (snap.exists) {
//         final data = snap.data() ?? {};

//         final isPlus = data['isPlus'] == true;

//         _isPlus.value = isPlus;

//         // --------------------------------------------------------
//         // FIRST TIME / OLD USER WITHOUT CREDIT FIELD
//         // --------------------------------------------------------

//         if (!data.containsKey('freeCredits')) {
//           final resetAt = _nextWeeklyReset();

//           await ref.set({
//             'freeCredits': kWeeklyFreeCredits,
//             'creditsResetAt': Timestamp.fromDate(resetAt),
//           }, SetOptions(merge: true));

//           _freeCredits.value = kWeeklyFreeCredits;
//           _creditsResetAt.value = resetAt;

//           _cacheValues();

//           print(
//             '[Subscription] First-time credits initialized: '
//             '$kWeeklyFreeCredits',
//           );
//         } else {
//           final credits = (data['freeCredits'] as num?)?.toInt() ?? 0;

//           final resetTimestamp = data['creditsResetAt'] as Timestamp?;

//           DateTime? resetAt = resetTimestamp?.toDate();

//           // ------------------------------------------------------
//           // OLD USER WITHOUT resetAt
//           // ------------------------------------------------------

//           if (resetAt == null) {
//             resetAt = _nextWeeklyReset();

//             await ref.set({
//               'creditsResetAt': Timestamp.fromDate(resetAt),
//             }, SetOptions(merge: true));
//           }

//           // ------------------------------------------------------
//           // WEEK EXPIRED
//           // ------------------------------------------------------

//           if (DateTime.now().isAfter(resetAt)) {
//             resetAt = _nextWeeklyReset();

//             await ref.set({
//               'freeCredits': kWeeklyFreeCredits,
//               'creditsResetAt': Timestamp.fromDate(resetAt),
//             }, SetOptions(merge: true));

//             _freeCredits.value = kWeeklyFreeCredits;
//             _creditsResetAt.value = resetAt;

//             print(
//               '[Subscription] Weekly credits renewed: '
//               '$kWeeklyFreeCredits',
//             );
//           } else {
//             _freeCredits.value = credits;
//             _creditsResetAt.value = resetAt;
//           }

//           _cacheValues();
//         }
//       } else {
//         // --------------------------------------------------------
//         // USER DOCUMENT DOES NOT EXIST
//         // --------------------------------------------------------

//         final resetAt = _nextWeeklyReset();

//         await ref.set({
//           'isPlus': false,
//           'freeCredits': kWeeklyFreeCredits,
//           'creditsResetAt': Timestamp.fromDate(resetAt),
//         }, SetOptions(merge: true));

//         _isPlus.value = false;
//         _freeCredits.value = kWeeklyFreeCredits;
//         _creditsResetAt.value = resetAt;

//         _cacheValues();

//         print(
//           '[Subscription] New user created with '
//           '$kWeeklyFreeCredits weekly credits',
//         );
//       }
//     } catch (e) {
//       print('[Subscription] bindUser error: $e');
//     }

//     // ------------------------------------------------------------
//     // REAL-TIME LISTENER
//     // ------------------------------------------------------------

//     _userSubscription = ref.snapshots().listen((snap) async {
//       if (!snap.exists) return;

//       final data = snap.data() ?? {};

//       final plus = data['isPlus'] == true;

//       _isPlus.value = plus;

//       final credits = (data['freeCredits'] as num?)?.toInt() ?? 0;

//       final timestamp = data['creditsResetAt'] as Timestamp?;

//       final resetAt = timestamp?.toDate();

//       _freeCredits.value = credits;
//       _creditsResetAt.value = resetAt;

//       _cacheValues();
//     });
//   }

//   // ============================================================
//   // WEEKLY RESET DATE
//   // ============================================================

//   DateTime _nextWeeklyReset() {
//     final now = DateTime.now();

//     // 7 days from now.
//     return now.add(const Duration(days: 7));
//   }

//   // ============================================================
//   // CACHE
//   // ============================================================

//   void _cacheValues() {
//     _box.write(_kPlus, _isPlus.value);
//     _box.write(_kCredits, _freeCredits.value);

//     final resetAt = _creditsResetAt.value;

//     if (resetAt != null) {
//       _box.write(_kResetAt, resetAt.toIso8601String());
//     }
//   }

//   // ============================================================
//   // LOGOUT
//   // ============================================================

//   Future<void> onLogout() async {
//     _uid = null;

//     await _userSubscription?.cancel();

//     _userSubscription = null;

//     _isPlus.value = false;
//     _freeCredits.value = 0;
//     _creditsResetAt.value = null;
//   }

//   // ============================================================
//   // GETTERS
//   // ============================================================

//   bool get isPlus => _isPlus.value;

//   int get freeCredits => _freeCredits.value;

//   DateTime? get creditsResetAt => _creditsResetAt.value;

//   RxBool get isPlusListenable => _isPlus;

//   RxInt get freeCreditsListenable => _freeCredits;

//   // ============================================================
//   // CAPABILITY
//   // ============================================================

//   bool canUseRecipeImport() {
//     return isPlus || freeCredits > 0;
//   }

//   bool canUseNutrition() => isPlus;

//   bool canUseCookingAssistant() => isPlus;

//   bool canUseMealPlanner() => isPlus;

//   bool canUseConverter() => isPlus;

//   bool canExportPDF() => isPlus;

//   bool canPrintRecipe() => isPlus;

//   // int remainingRecipeImports() {
//   //   return isPlus ? 999999 : freeCredits.clamp(0, kWeeklyFreeCredits);
//   // }

//   // ============================================================
//   // CONSUME CREDIT
//   // ============================================================

//   Future<bool> consumeCredit() async {
//     if (isPlus) {
//       return true;
//     }

//     final ref = _ref;

//     if (ref == null) {
//       return false;
//     }

//     try {
//       final success = await FirebaseFirestore.instance.runTransaction<bool>((
//         transaction,
//       ) async {
//         final snap = await transaction.get(ref);

//         if (!snap.exists) {
//           return false;
//         }

//         final data = snap.data() ?? {};

//         final currentCredits = (data['freeCredits'] as num?)?.toInt() ?? 0;

//         final timestamp = data['creditsResetAt'] as Timestamp?;

//         DateTime? resetAt = timestamp?.toDate();

//         // ------------------------------------------------------
//         // SAFETY:
//         // If reset date is missing, initialize it.
//         // ------------------------------------------------------

//         if (resetAt == null) {
//           resetAt = _nextWeeklyReset();

//           transaction.update(ref, {
//             'creditsResetAt': Timestamp.fromDate(resetAt),
//           });
//         }

//         // ------------------------------------------------------
//         // WEEK EXPIRED
//         // ------------------------------------------------------

//         if (DateTime.now().isAfter(resetAt)) {
//           final newResetAt = _nextWeeklyReset();

//           transaction.update(ref, {
//             'freeCredits': kWeeklyFreeCredits - 1,
//             'creditsResetAt': Timestamp.fromDate(newResetAt),
//           });

//           return true;
//         }

//         // ------------------------------------------------------
//         // NO CREDIT
//         // ------------------------------------------------------

//         if (currentCredits <= 0) {
//           return false;
//         }

//         // ------------------------------------------------------
//         // CONSUME 1
//         // ------------------------------------------------------

//         transaction.update(ref, {'freeCredits': currentCredits - 1});

//         return true;
//       });

//       if (success) {
//         /*
//          * Don't manually decrement here.
//          *
//          * Firestore snapshot listener will update the local
//          * reactive value.
//          */
//         print('[Subscription] Credit consumed successfully');
//       }

//       return success;
//     } catch (e) {
//       print('[Subscription] consumeCredit error: $e');

//       return false;
//     }
//   }

//   // ============================================================
//   // SET PLUS
//   // ============================================================

//   Future<void> setPlus(bool value) async {
//     _isPlus.value = value;

//     _box.write(_kPlus, value);

//     await _ref?.set({'isPlus': value}, SetOptions(merge: true));
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';

class SubscriptionService extends GetxController {
  /// Legacy fallback constant. Credit amounts are now driven by Remote Config
  /// ([RemoteConfigService.newUserCredit] / [RemoteConfigService.weeklyRenewalCredit]);
  /// this is only kept as a last-resort default reference.
  static const int kWeeklyFreeCredits = 5;

  // Live credit amounts from Remote Config (console-tunable, no app update).
  int get _newUserCredit => RemoteConfigService.instance.newUserCredit;
  int get _weeklyRenewalCredit => RemoteConfigService.instance.weeklyRenewalCredit;

  static SubscriptionService get instance {
    if (Get.isRegistered<SubscriptionService>()) {
      return Get.find<SubscriptionService>();
    }

    return Get.put(SubscriptionService(), permanent: true);
  }

  final GetStorage _box = GetStorage();

  static const String _kPlus = 'sub_is_plus';
  static const String _kCredits = 'sub_free_credits';
  static const String _kResetAt = 'sub_credits_reset_at';

  // ============================================================
  // REACTIVE VALUES
  // ============================================================

  final RxBool _isPlus = false.obs;

  final RxInt _freeCredits = 0.obs;

  final Rxn<DateTime> _creditsResetAt = Rxn<DateTime>();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _uid;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    _loadCachedValues();
  }

  // ============================================================
  // LOAD CACHE
  // ============================================================

  void _loadCachedValues() {
    _isPlus.value = _box.read(_kPlus) ?? false;

    final cachedCredits = _box.read(_kCredits);

    if (cachedCredits is num) {
      _freeCredits.value = cachedCredits.toInt();
    } else {
      _freeCredits.value = 0;
    }

    final cachedResetAt = _box.read(_kResetAt);

    if (cachedResetAt is String) {
      _creditsResetAt.value = DateTime.tryParse(cachedResetAt);
    }

    print('[Subscription] Cached credits: ${_freeCredits.value}');
  }

  // ============================================================
  // FIRESTORE USER REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>>? get _ref {
    if (_uid == null || _uid!.isEmpty) {
      return null;
    }

    return _firestore.collection('users').doc(_uid);
  }

  // ============================================================
  // BIND CURRENT USER
  // ============================================================

  Future<void> bindUser(String uid) async {
    if (uid.isEmpty) {
      print('[Subscription] Cannot bind user: UID is empty');
      return;
    }

    // Same user already connected.
    if (_uid == uid && _userSubscription != null) {
      print('[Subscription] User already bound: $uid');
      return;
    }

    // Cancel old listener.
    await _userSubscription?.cancel();

    _userSubscription = null;

    _uid = uid;

    print('[Subscription] Binding Firebase user: $_uid');

    final ref = _ref;

    if (ref == null) {
      return;
    }

    // ==========================================================
    // FIRST FETCH FROM FIREBASE
    // ==========================================================

    try {
      final snap = await ref.get();

      if (!snap.exists) {
        await _createUserCredits(ref);
      } else {
        await _processUserDocument(ref, snap.data() ?? {});
      }
    } catch (e) {
      print('[Subscription] Initial Firebase fetch error: $e');
    }

    // ==========================================================
    // REALTIME FIRESTORE LISTENER
    // ==========================================================

    _userSubscription = ref.snapshots().listen(
      (snap) async {
        if (!snap.exists) {
          return;
        }

        try {
          final data = snap.data() ?? {};

          final plus = data['isPlus'] == true;

          _isPlus.value = plus;

          final credits = _readCredits(data['freeCredits']);

          final timestamp = data['creditsResetAt'];

          DateTime? resetAt;

          if (timestamp is Timestamp) {
            resetAt = timestamp.toDate();
          }

          _freeCredits.value = credits;

          _creditsResetAt.value = resetAt;

          _cacheValues();

          print('[Subscription] Firebase realtime update:');

          print('[Subscription] isPlus = $plus');

          print('[Subscription] freeCredits = $credits');

          print('[Subscription] resetAt = $resetAt');
        } catch (e) {
          print('[Subscription] Snapshot listener error: $e');
        }
      },
      onError: (error) {
        print('[Subscription] Firestore listener error: $error');
      },
    );
  }

  // ============================================================
  // CREATE NEW USER CREDIT DATA
  // ============================================================

  Future<void> _createUserCredits(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final resetAt = _nextWeeklyReset();
    final grant = _newUserCredit;

    await ref.set({
      'isPlus': false,
      'freeCredits': grant,
      'creditsResetAt': Timestamp.fromDate(resetAt),
    }, SetOptions(merge: true));

    _isPlus.value = false;

    _freeCredits.value = grant;

    _creditsResetAt.value = resetAt;

    _cacheValues();

    print('[Subscription] New user created.');

    print(
      '[Subscription] freeCredits (new_user_credit) = '
      '$grant',
    );
  }

  // ============================================================
  // PROCESS FIREBASE USER DOCUMENT
  // ============================================================

  Future<void> _processUserDocument(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    // ==========================================================
    // PLUS
    // ==========================================================

    final isPlus = data['isPlus'] == true;

    _isPlus.value = isPlus;

    // ==========================================================
    // FREE CREDITS
    // ==========================================================

    final hasCredits = data.containsKey('freeCredits');

    // Old user without freeCredits — treat this first-time grant like a new
    // user (new_user_credit).
    if (!hasCredits) {
      final resetAt = _nextWeeklyReset();
      final grant = _newUserCredit;

      await ref.set({
        'freeCredits': grant,
        'creditsResetAt': Timestamp.fromDate(resetAt),
      }, SetOptions(merge: true));

      _freeCredits.value = grant;

      _creditsResetAt.value = resetAt;

      _cacheValues();

      print(
        '[Subscription] freeCredits field created (new_user_credit): '
        '$grant',
      );

      return;
    }

    final credits = _readCredits(data['freeCredits']);

    // ==========================================================
    // RESET DATE
    // ==========================================================

    DateTime? resetAt;

    final resetTimestamp = data['creditsResetAt'];

    if (resetTimestamp is Timestamp) {
      resetAt = resetTimestamp.toDate();
    }

    // If reset date doesn't exist.
    if (resetAt == null) {
      resetAt = _nextWeeklyReset();

      await ref.set({
        'creditsResetAt': Timestamp.fromDate(resetAt),
      }, SetOptions(merge: true));
    }

    // ==========================================================
    // WEEK EXPIRED
    // ==========================================================

    if (DateTime.now().isAfter(resetAt)) {
      final newResetAt = _nextWeeklyReset();
      final renewal = _weeklyRenewalCredit;

      await ref.set({
        'freeCredits': renewal,
        'creditsResetAt': Timestamp.fromDate(newResetAt),
      }, SetOptions(merge: true));

      _freeCredits.value = renewal;

      _creditsResetAt.value = newResetAt;

      _cacheValues();

      print(
        '[Subscription] Weekly credits reset (weekly_renewal_credit): '
        '$renewal',
      );

      return;
    }

    // ==========================================================
    // NORMAL
    // ==========================================================

    _freeCredits.value = credits;

    _creditsResetAt.value = resetAt;

    _cacheValues();

    print(
      '[Subscription] Firebase credits loaded: '
      '$credits',
    );
  }

  // ============================================================
  // READ CREDITS SAFELY
  // ============================================================

  int _readCredits(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  // ============================================================
  // WEEKLY RESET DATE
  // ============================================================

  DateTime _nextWeeklyReset() {
    return DateTime.now().add(const Duration(days: 7));
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
  // MANUALLY REFRESH FROM FIREBASE
  // ============================================================

  Future<void> refreshFromFirebase() async {
    final ref = _ref;

    if (ref == null) {
      print(
        '[Subscription] refreshFromFirebase: '
        'No user bound.',
      );
      return;
    }

    try {
      final snap = await ref.get();

      if (!snap.exists) {
        await _createUserCredits(ref);
        return;
      }

      await _processUserDocument(ref, snap.data() ?? {});

      print('[Subscription] Manual Firebase refresh complete.');
    } catch (e) {
      print('[Subscription] refreshFromFirebase error: $e');
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> onLogout() async {
    await _userSubscription?.cancel();

    _userSubscription = null;

    _uid = null;

    _isPlus.value = false;

    _freeCredits.value = 0;

    _creditsResetAt.value = null;

    print('[Subscription] User logged out.');
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

  // ============================================================
  // CONSUME CREDIT
  // ============================================================

  Future<bool> consumeCredit() async {
    // PLUS users don't consume free credits.
    if (isPlus) {
      return true;
    }

    final ref = _ref;

    if (ref == null) {
      print(
        '[Subscription] consumeCredit: '
        'No Firebase user.',
      );

      return false;
    }

    try {
      final success = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        final snap = await transaction.get(ref);

        if (!snap.exists) {
          return false;
        }

        final data = snap.data() ?? {};

        final currentCredits = _readCredits(data['freeCredits']);

        final timestamp = data['creditsResetAt'];

        DateTime? resetAt;

        if (timestamp is Timestamp) {
          resetAt = timestamp.toDate();
        }

        // ======================================================
        // RESET DATE MISSING
        // ======================================================

        if (resetAt == null) {
          resetAt = _nextWeeklyReset();

          transaction.update(ref, {
            'creditsResetAt': Timestamp.fromDate(resetAt),
          });
        }

        // ======================================================
        // WEEK EXPIRED
        // ======================================================

        if (DateTime.now().isAfter(resetAt)) {
          final newResetAt = _nextWeeklyReset();
          final renewal = _weeklyRenewalCredit;

          // Renew the week, then spend this import from it. If the renewal
          // amount is 0, there is nothing to spend — renew to 0 and deny.
          if (renewal <= 0) {
            transaction.update(ref, {
              'freeCredits': 0,
              'creditsResetAt': Timestamp.fromDate(newResetAt),
            });
            return false;
          }

          transaction.update(ref, {
            'freeCredits': renewal - 1,
            'creditsResetAt': Timestamp.fromDate(newResetAt),
          });

          return true;
        }

        // ======================================================
        // NO CREDITS
        // ======================================================

        if (currentCredits <= 0) {
          return false;
        }

        // ======================================================
        // CONSUME 1 CREDIT
        // ======================================================

        transaction.update(ref, {'freeCredits': currentCredits - 1});

        return true;
      });

      if (success) {
        print('[Subscription] Credit consumed.');
      } else {
        print('[Subscription] No free credits left.');
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

    final ref = _ref;

    if (ref != null) {
      await ref.set({'isPlus': value}, SetOptions(merge: true));
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void onClose() {
    _userSubscription?.cancel();

    _userSubscription = null;

    super.onClose();
  }
}
