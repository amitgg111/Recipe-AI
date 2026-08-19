import 'package:flutter/widgets.dart';

/// Global observer for full-page route pushes/pops.
///
/// Screens that live permanently inside the Home [IndexedStack] (e.g. the Meal
/// Plan tab) never rebuild via `initState` when a route pushed above Home is
/// popped. Subscribing to this observer lets such a screen react to
/// `didPopNext` — i.e. becoming visible again — so it can snap back to the
/// current week/month instead of showing whatever the user last browsed to.
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
