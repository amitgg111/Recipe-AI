import 'package:flutter/widgets.dart';
import 'package:recipe_ai/Service/analytics_service.dart';

const Map<String, String> _untrackedRouteScreens = {
  '/': 'SplashScreen',
  '/auth-wrapper': 'AuthWrapper',
  '/signup': 'SignUpScreen',
  '/cookbooks-empty': 'CookbooksEmptyScreen',
  '/cookbooks-home': 'CookbooksHomeScreen',
  '/cookbook-detail': 'CookbookDetailScreen',
  '/cookbook-detail-empty': 'CookbookDetailEmptyScreen',
  '/import-picker': 'ImportPickerScreen',
  '/recipes-grid': 'RecipesGridScreen',
  '/recipe-detail-edit': 'RecipeDetailEditScreen',
  '/cook-mode-step': 'CookModeStepScreen',
  '/cook-mode-timer': 'CookModeTimerScreen',
  '/cook-mode-paused': 'CookModePausedScreen',
  '/cook-mode-chip': 'CookModeChipScreen',
  '/cook-mode-ingredients': 'CookModeIngredientsScreen',
  '/cook-mode-timer-done': 'CookModeTimerDoneScreen',
  '/cook-mode-all-timers': 'CookModeAllTimersScreen',
  '/cook-mode-finish': 'CookModeFinishScreen',
  '/discover-feed': 'DiscoverFeedScreen',
  '/public-recipe': 'PublicRecipeScreen',
  '/meal-plan-day': 'MealPlanDayScreen',
  '/meal-plan-calendar': 'MealPlanCalendarScreen',
};

void _trackMissingScreen(Route<dynamic>? route) {
  final name = route?.settings.name;
  final screenName = name == null ? null : _untrackedRouteScreens[name];
  if (screenName != null) {
    AnalyticsService.instance.trackScreen(screenName);
  }
}

/// Global observer for full-page route pushes/pops.
///
/// Screens that live permanently inside the Home [IndexedStack] (e.g. the Meal
/// Plan tab) never rebuild via `initState` when a route pushed above Home is
/// popped. Subscribing to this observer lets such a screen react to
/// `didPopNext` — i.e. becoming visible again — so it can snap back to the
/// current week/month instead of showing whatever the user last browsed to.
class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackMissingScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _trackMissingScreen(newRoute);
  }

}

final AppRouteObserver appRouteObserver = AppRouteObserver();
