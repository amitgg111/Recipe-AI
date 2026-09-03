import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_ai/Controllers/cuisine_controller.dart';
import 'package:recipe_ai/Controllers/internet_controller.dart';
import 'package:recipe_ai/Service/ai_translation_service.dart';

import 'package:recipe_ai/Service/language_service.dart';
import 'package:recipe_ai/Service/remote_config_service.dart';
import 'package:recipe_ai/Service/recipe_auto_translate_service.dart';
import 'package:recipe_ai/translations/app_translations.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/import_web_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
import 'package:recipe_ai/Controllers/settings_controller.dart';
import 'package:recipe_ai/Service/subscription_service.dart';
import 'package:recipe_ai/Service/revenuecat_service.dart';
import 'package:recipe_ai/Controllers/onboarding_controller.dart';
import 'package:recipe_ai/Controllers/notification_controller.dart';
import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';
import 'package:recipe_ai/Core/Routes/app_route_observer.dart';
import 'package:recipe_ai/Core/Theme/app_theme_controller.dart';
import 'package:recipe_ai/View/Splash/spalsh_screen.dart';

import 'package:recipe_ai/Service/auth_service.dart';
import 'package:recipe_ai/Service/notification_service.dart';
import 'package:recipe_ai/Service/local_notification_service.dart';
import 'package:recipe_ai/Service/mixpanel_service.dart';
import 'package:recipe_ai/firebase_options.dart';
import 'package:recipe_ai/theme/app_theme.dart' as new_theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MixpanelService.instance.init();
  // Start pulling the live credit amounts (new-user / weekly-renewal) from
  // Remote Config as early as possible. Fire-and-forget: the getters return a
  // safe fallback until the fetch activates, so nothing needs to block on it.
  await RemoteConfigService.instance.init();
  await GetStorage.init();
  // Restore the saved language before the first frame so the app opens already
  // localized (defaults to English when nothing is saved).
  await LanguageService.init();
  await LanguageService.detectCountry();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

    return true;
  };

  runApp(
    const MyApp(), // Wrap your app
  );

  // Work out which country the user is in, so the Language screen offers the
  // right options and splash knows which model to pre-download. Resolved here
  // (not in splash) because both of those read it, and it must not race them.

  await GetStorage.init();

  Get.put(CuisineController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(MealPlanController(), permanent: true);
  Get.put(GroceryStore(), permanent: true);
  Get.put(ImportWebController(), permanent: true);
  Get.put(RecipeEditorController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  Get.put(CookbookController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(SubscriptionService(), permanent: true);
  Get.put(InternetController(), permanent: true);
  // In-app purchases (RevenueCat). Configures only once real keys are set in
  // RevenueCatConfig; entitlement changes drive SubscriptionService.isPlus.
  Get.put(RevenueCatService(), permanent: true);
  unawaited(RevenueCatService.instance.configure());
  await NotificationService.instance.init();
  await LocalNotificationService.instance.init();
  _bindNotificationsToAuth();

  // 🆕 App-level periodic recipe auto-translate check — permanent, splash
  // screen dispose થાય તોય ચાલુ રહે.
  RecipeAutoTranslateService.instance.start();
  Get.put(OnboardingController(), permanent: true);
  // Real-time in-app notification feed + unread badge (self-binds to auth).
  Get.put(NotificationController(), permanent: true);

  final shareService = Get.put(ShareIntentService(), permanent: true);

  await shareService.init();

  // Notifications: initialise the SDKs (no permission prompt here) and keep
  // the user's preferences + scheduled reminders bound to the signed-in user.
  await NotificationService.instance.init();
  await LocalNotificationService.instance.init();
}

/// Links push/local notifications to the auth session: on sign-in the OneSignal
/// user is linked and the Firestore-backed toggles are loaded + reconciled; on
/// sign-out scheduled reminders are cancelled. Fires immediately with the
/// current user, so an already-signed-in user is bound on cold start.
void _bindNotificationsToAuth() {
  final settings = Get.find<SettingsController>();
  final subscription = Get.find<SubscriptionService>();
  AuthService.authStateChanges.listen((user) async {
    if (user != null) {
      await MixpanelService.instance.identify(user.uid);
      await MixpanelService.instance.setUserProfile({
        'email': user.email ?? '',
        'display_name': user.displayName ?? '',
      });
      await NotificationService.instance.loginUser(user.uid);
      await settings.bindUser(user.uid);
      await subscription.bindUser(user.uid);
      await RemoteConfigService.instance.refresh();
      await RevenueCatService.instance.loginUser(user.uid);
      unawaited(AiTranslationService.prepareAllSupportedLanguages());
      unawaited(AiTranslationService.prepareAlternateLanguages());
    } else {
      await MixpanelService.instance.reset();
      await settings.onLogout();
      subscription.onLogout();
      await RevenueCatService.instance.logoutUser();
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MixpanelService.instance.pingLastActive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Recipe AI',
      debugShowCheckedModeBanner: false,
      // ── Localization ──
      translations: AppTranslations(),
      locale: LanguageService.locale,
      fallbackLocale: LanguageService.fallbackLocale,
      supportedLocales: LanguageService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Single-theme app: always the orange (light) theme. Dark mode removed —
      // darkTheme also points at the orange theme so nothing can render dark.
      theme: new_theme.AppTheme.light,
      darkTheme: new_theme.AppTheme.light,
      themeMode: ThemeMode.light,
      // Lets always-alive Home tabs (e.g. Meal Plan) know when a route pushed
      // above Home is popped, so they can reset to the current period.
      navigatorObservers: [appRouteObserver],
      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            GetBuilder<InternetController>(
              init: Get.find<InternetController>(),
              builder: (controller) {
                return Obx(() {
                  if (!controller.hasInternet.value) {
                    return const NoInternetOverlay();
                  }
                  return const SizedBox.shrink();
                });
              },
            ),
          ],
        );
      },
    );
  }
}
