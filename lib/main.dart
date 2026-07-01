import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Controllers/import_web_controller.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';
import 'package:recipe_ai/Controllers/profile_controller.dart';
import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
import 'package:recipe_ai/Controllers/share_intent_service_controller.dart';
import 'package:recipe_ai/Core/Routes/app_routes.dart';
import 'package:recipe_ai/Core/Theme/app_theme_controller.dart';
import 'package:recipe_ai/View/Splash/spalsh_screen.dart';
import 'package:recipe_ai/firebase_options.dart';
import 'package:recipe_ai/theme/app_theme.dart' as new_theme;

// Onboarding screens
import 'package:recipe_ai/screens/onboarding/welcome_screen.dart';
import 'package:recipe_ai/screens/onboarding/social_proof_screen.dart';
import 'package:recipe_ai/screens/onboarding/goals_screen.dart';
import 'package:recipe_ai/screens/onboarding/thats_great_screen.dart';
import 'package:recipe_ai/screens/onboarding/goals_happen_screen.dart';
import 'package:recipe_ai/screens/onboarding/when_to_cook_screen.dart';
import 'package:recipe_ai/screens/onboarding/notifications_screen.dart';
import 'package:recipe_ai/screens/onboarding/how_did_you_hear_screen.dart';
import 'package:recipe_ai/screens/onboarding/recipe_sources_screen.dart';
import 'package:recipe_ai/screens/onboarding/awesome_import_screen.dart';
import 'package:recipe_ai/screens/onboarding/age_screen.dart';
import 'package:recipe_ai/screens/onboarding/setting_up_screen.dart';
import 'package:recipe_ai/screens/onboarding/plus_intro_screen.dart';
import 'package:recipe_ai/screens/onboarding/plus_comparison_screen.dart';
import 'package:recipe_ai/screens/onboarding/trial_chooser_screen.dart';

// Auth screens
import 'package:recipe_ai/screens/auth/create_account_screen.dart';
import 'package:recipe_ai/screens/auth/login_screen.dart';
import 'package:recipe_ai/screens/auth/sign_up_screen.dart';
import 'package:recipe_ai/screens/auth/forgot_password_screen.dart';
// Cookbook screens
import 'package:recipe_ai/screens/cookbooks/cookbooks_empty_screen.dart';
import 'package:recipe_ai/screens/cookbooks/cookbooks_home_screen.dart';
import 'package:recipe_ai/screens/cookbooks/cookbook_detail_screen.dart';
import 'package:recipe_ai/screens/cookbooks/cookbook_detail_empty_screen.dart';

// Cookbook variant screens
import 'package:recipe_ai/screens/cookbooks/recipes_grid_screen.dart';

// Import screens
import 'package:recipe_ai/screens/import/import_picker_screen.dart';
import 'package:recipe_ai/screens/import/import_processing_screen.dart';
import 'package:recipe_ai/screens/import/import_complete_screen.dart';

// Recipe screens
import 'package:recipe_ai/screens/recipe/recipe_detail_view_screen.dart';
import 'package:recipe_ai/screens/recipe/recipe_detail_edit_screen.dart';

// Cook Mode screens
import 'package:recipe_ai/screens/cook_mode/cook_mode_step_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_timer_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_paused_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_chip_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_ingredients_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_timer_done_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_all_timers_screen.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_lock_notification.dart';
import 'package:recipe_ai/screens/cook_mode/cook_mode_finish_screen.dart';

// Discover screens
import 'package:recipe_ai/screens/discover/discover_feed_screen.dart';
import 'package:recipe_ai/screens/discover/public_recipe_screen.dart';

// Meal Plan screens
import 'package:recipe_ai/screens/meal_plan/meal_plan_day_screen.dart';
import 'package:recipe_ai/screens/meal_plan/meal_plan_calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GetStorage.init();
  runApp(const MyApp());

  Get.put(ThemeController(), permanent: true);
  Get.put(HomeController(), permanent: true);
  Get.put(MealPlanController(), permanent: true);
  Get.put(GroceryStore(), permanent: true);
  Get.put(ImportWebController(), permanent: true);
  Get.put(RecipeEditorController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  Get.put(CookbookController(), permanent: true);

  final shareService = Get.put(ShareIntentService(), permanent: true);

  await shareService.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Recipe AI',
      debugShowCheckedModeBanner: false,
      // Single-theme app: always the orange (light) theme. Dark mode removed —
      // darkTheme also points at the orange theme so nothing can render dark.
      theme: new_theme.AppTheme.light,
      darkTheme: new_theme.AppTheme.light,
      themeMode: ThemeMode.light,
      home: SplashScreen(),
      getPages: [
        // Onboarding
        GetPage(name: AppRoutes.onboarding, page: () => const WelcomeScreen()),
        GetPage(name: AppRoutes.socialProof, page: () => const SocialProofScreen()),
        GetPage(name: AppRoutes.goals, page: () => const GoalsScreen()),
        GetPage(name: AppRoutes.thatsGreat, page: () => const ThatsGreatScreen()),
        GetPage(name: AppRoutes.goalsHappen, page: () => const GoalsHappenScreen()),
        GetPage(name: AppRoutes.whenToCook, page: () => const WhenToCookScreen()),
        GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen()),
        GetPage(name: AppRoutes.howDidYouHear, page: () => const HowDidYouHearScreen()),
        GetPage(name: AppRoutes.recipeSources, page: () => const RecipeSourcesScreen()),
        GetPage(name: AppRoutes.awesomeImport, page: () => const AwesomeImportScreen()),
        GetPage(name: AppRoutes.age, page: () => const AgeScreen()),
        GetPage(name: AppRoutes.settingUp, page: () => const SettingUpScreen()),
        GetPage(name: AppRoutes.plusIntro, page: () => const PlusIntroScreen()),
        GetPage(name: AppRoutes.plusComparison, page: () => const PlusComparisonScreen()),
        GetPage(name: AppRoutes.trialChooser, page: () => const TrialChooserScreen()),

        // Auth
        GetPage(name: AppRoutes.createAccount, page: () => const CreateAccountScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.signup, page: () => const SignUpScreen()),
        GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),

        // Cookbooks
        GetPage(name: AppRoutes.cookbooksEmpty, page: () => const CookbooksEmptyScreen()),
        GetPage(name: AppRoutes.cookbooksHome, page: () => const CookbooksHomeScreen()),
        GetPage(name: AppRoutes.cookbookDetail, page: () => const CookbookDetailScreen()),
        GetPage(name: AppRoutes.cookbookDetailEmpty, page: () => const CookbookDetailEmptyScreen()),

        // Cookbook variants
        GetPage(name: AppRoutes.recipesGrid, page: () => const RecipesGridScreen()),

        // Import
        GetPage(name: AppRoutes.importPicker, page: () => const ImportPickerScreen()),
        GetPage(name: AppRoutes.importProcessing, page: () => const ImportProcessingScreen()),
        GetPage(name: AppRoutes.importComplete, page: () => const ImportCompleteScreen()),

        // Recipe
        GetPage(name: AppRoutes.recipeDetailView, page: () => const RecipeDetailViewScreen()),
        GetPage(name: AppRoutes.recipeDetailEdit, page: () => const RecipeDetailEditScreen()),

        // Cook Mode
        GetPage(name: AppRoutes.cookModeStep, page: () => const CookModeStepScreen()),
        GetPage(name: AppRoutes.cookModeTimer, page: () => const CookModeTimerScreen()),
        GetPage(name: AppRoutes.cookModePaused, page: () => const CookModePausedScreen()),
        GetPage(name: AppRoutes.cookModeChip, page: () => const CookModeChipScreen()),
        GetPage(name: AppRoutes.cookModeIngredients, page: () => const CookModeIngredientsScreen()),
        GetPage(name: AppRoutes.cookModeTimerDone, page: () => const CookModeTimerDoneScreen()),
        GetPage(name: AppRoutes.cookModeAllTimers, page: () => const CookModeAllTimersScreen()),
        GetPage(name: AppRoutes.cookModeLockNotification, page: () => const CookModeLockNotification()),
        GetPage(name: AppRoutes.cookModeFinish, page: () => const CookModeFinishScreen()),

        // Discover
        GetPage(name: AppRoutes.discoverFeed, page: () => const DiscoverFeedScreen()),
        GetPage(name: AppRoutes.publicRecipe, page: () => const PublicRecipeScreen()),

        // Meal Plan
        GetPage(name: AppRoutes.mealPlanDay, page: () => const MealPlanDayScreen()),
        GetPage(name: AppRoutes.mealPlanCalendar, page: () => const MealPlanCalendarScreen()),
      ],
    );
  }
}
