  import 'dart:developer';

  import 'package:flutter/services.dart';
  import 'package:get/get.dart';
  import 'package:purchases_flutter/purchases_flutter.dart';
  import 'package:url_launcher/url_launcher.dart';

  import 'package:recipe_ai/Service/revenuecat_config.dart';
  import 'package:recipe_ai/Service/subscription_service.dart';
  import 'package:recipe_ai/Service/analytics_service.dart';

  /// Wraps the RevenueCat SDK.
  ///
  /// Responsibilities:
  ///  • configure the SDK once (with the platform's public key),
  ///  • fetch the current offering — the Monthly + Yearly packages, whose
  ///    **price and title come straight from the store via RevenueCat**,
  ///  • run the purchase + restore flows,
  ///  • map the `plus` entitlement onto [SubscriptionService] so every Plus gate
  ///    in the app flips automatically (purchase, renewal, expiry, restore, or a
  ///    change made on another device all funnel through the update listener).
  ///
  /// The paywall reads [monthly] / [yearly] for the localized price strings and
  /// calls [purchase] / [restore]; it never talks to the SDK directly.
  class RevenueCatService extends GetxController {
    static RevenueCatService get instance => Get.isRegistered<RevenueCatService>()
        ? Get.find<RevenueCatService>()
        : Get.put(RevenueCatService(), permanent: true);

    /// The current offering (reactive → the paywall rebuilds once it loads).
    final Rxn<Offering> offering = Rxn<Offering>();

    /// True while offerings are being (re)fetched.
    final RxBool loading = false.obs;

    /// The latest customer info (reactive).
    final Rxn<CustomerInfo> customerInfo = Rxn<CustomerInfo>();

    bool _configured = false;
    bool get isReady => _configured;

    // ── Packages the paywall renders ───────────────────────────────────────────

    Package? get monthly =>
        offering.value?.monthly ?? _firstOfType(PackageType.monthly);

    Package? get yearly =>
        offering.value?.annual ?? _firstOfType(PackageType.annual);

    Package? _firstOfType(PackageType type) {
      for (final p in offering.value?.availablePackages ?? const <Package>[]) {
        if (p.packageType == type) return p;
      }
      return null;
    }

    // ── Lifecycle ──────────────────────────────────────────────────────────────

    /// Configure the SDK once (call from `main`, after Firebase). No-op until real
    /// API keys are set in [RevenueCatConfig], so the app runs fine without them.
    Future<void> configure() async {
      if (_configured || !RevenueCatConfig.isConfigured) return;
      _configured = true;

      await Purchases.setLogLevel(LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(RevenueCatConfig.apiKey));

      // Keep Plus in sync for the whole session (purchase / renew / expire /
      // restore / cross-device changes all arrive here).
      Purchases.addCustomerInfoUpdateListener(_syncEntitlement);

      await fetchOfferings();
      try {
        _syncEntitlement(await Purchases.getCustomerInfo());
      } catch (_) {
        // offline — cached Plus state stands until we can reach the store
      }
    }

    /// Tie purchases to the signed-in Firebase user, so the subscription follows
    /// the account across devices and reinstalls. Call on sign-in.
    Future<void> loginUser(String uid) async {
      if (!_configured) return;
      try {
        final res = await Purchases.logIn(uid);
        _syncEntitlement(res.customerInfo);
      } catch (_) {}
    }

    /// Call on sign-out (drops back to an anonymous RevenueCat user).
    Future<void> logoutUser() async {
      if (!_configured) return;
      try {
        await Purchases.logOut();
      } catch (_) {}
    }

    // ── Offerings ──────────────────────────────────────────────────────────────

    Future<void> fetchOfferings() async {
      if (!_configured) return;
      loading.value = true;
      try {
        final offerings = await Purchases.getOfferings();
        offering.value = offerings.current;
      } catch (_) {
        // leave null → paywall shows its fallback prices
      } finally {
        loading.value = false;
      }
    }

    // ── Purchase / restore / manage ───────────────────────────────────────────────

    /// Buy [package]. Returns true when Plus is active afterwards. A user
    /// cancellation returns false (no error). Other store errors rethrow so the
    /// caller can surface a message.
    Future<bool> purchase(Package package) async {
      if (!_configured) return false;
      try {
        final res = await Purchases.purchase(PurchaseParams.package(package));
        _syncEntitlement(res.customerInfo);
        final hasPlus = _hasPlus(res.customerInfo);
        if (hasPlus) {
          await AnalyticsService.instance.trackPurchase(
            itemId: package.identifier,
            value: package.storeProduct.price,
            currency: package.storeProduct.currencyCode,
          );
        }
        return hasPlus;
      } on PlatformException catch (e) {
        final code = PurchasesErrorHelper.getErrorCode(e);
        if (code == PurchasesErrorCode.purchaseCancelledError) return false;
        rethrow;
      }
    }

    /// Restore prior purchases (App Store / Play). Returns true if Plus is active.
    Future<bool> restore() async {
      if (!_configured) return false;
      final info = await Purchases.restorePurchases();
      _syncEntitlement(info);
      final hasPlus = _hasPlus(info);
      if (hasPlus) {
        await AnalyticsService.instance.trackEvent('subscription_restored');
      }
      return hasPlus;
    }

    /// Show the native subscription management screen, or launch the management URL.
    Future<void> showManageSubscriptions() async {
      if (!_configured) return;
      try {
        final info = await Purchases.getCustomerInfo();
        final url = info.managementURL;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }

        log("----${info.entitlements.active.toString()}");

        log("----${info.nonSubscriptionTransactions.toString()}");
      } catch (e) {
        log(e.toString());
        // Failed to get customer info or launch management URL.
      }
    }

    // ── Entitlement → app state ──────────────────────────────────────────────────

    EntitlementInfo? get activeEntitlement =>
        customerInfo.value?.entitlements.active[RevenueCatConfig.entitlementId];

    bool _hasPlus(CustomerInfo info) =>
        info.entitlements.active.containsKey(RevenueCatConfig.entitlementId);

    void _syncEntitlement(CustomerInfo info) {
      customerInfo.value = info;
      SubscriptionService.instance.setPlus(_hasPlus(info));
    }
  }
