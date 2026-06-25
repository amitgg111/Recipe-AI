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
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Core/Theme/app_theme_controller.dart';
import 'package:recipe_ai/View/Splash/spalsh_screen.dart';
import 'package:recipe_ai/firebase_options.dart';

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: SplashScreen(),
    );
  }
}
