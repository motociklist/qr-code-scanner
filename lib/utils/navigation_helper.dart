import 'package:flutter/material.dart';

/// Helper class for navigation to reduce code duplication
class NavigationHelper {
  /// Push a new screen onto the navigation stack
  static Future<T?> push<T>(
    BuildContext context,
    Widget screen, {
    bool replace = false,
  }) {
    final route = MaterialPageRoute<T>(builder: (_) => screen);
    if (replace) {
      return Navigator.pushReplacement(context, route);
    }
    return Navigator.push(context, route);
  }

  /// Push and remove all previous routes
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget screen,
  ) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<T>(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Pop the current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}

