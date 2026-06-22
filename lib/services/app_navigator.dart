import 'package:flutter/material.dart';

/// Root navigator for actions triggered outside the active route tree
/// (e.g. global in-app notification banners).
abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static BuildContext? get context => key.currentContext;

  static NavigatorState? get state => key.currentState;

  static Future<T?>? push<T>(Route<T> route) => state?.push(route);
}
