import 'package:flutter/material.dart';

/// Shared route observer so decorative, continuously-animating widgets (like
/// the Home screen's letter background) can pause their ticker while another
/// screen is pushed on top, and resume when they become visible again.
final RouteObserver<PageRoute<void>> appRouteObserver =
    RouteObserver<PageRoute<void>>();
