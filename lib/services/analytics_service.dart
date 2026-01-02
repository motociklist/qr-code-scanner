import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AnalyticsService {
  static AnalyticsService? _instance;
  AnalyticsService._();

  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }

  FirebaseAnalytics? _analytics;

  /// Initialize Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('Error initializing Firebase Analytics: $e');
    }
  }

  /// Log event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      Map<String, Object>? convertedParams;
      if (parameters != null) {
        convertedParams = parameters.map((key, value) => MapEntry(key, value as Object));
      }
      await _analytics?.logEvent(
        name: name,
        parameters: convertedParams,
      );
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  /// Log QR scan event
  Future<void> logQRScan(String type) async {
    await logEvent('qr_scan', parameters: {
      'qr_type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log QR creation event
  Future<void> logQRCreate(String type) async {
    await logEvent('qr_create', parameters: {
      'qr_type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log subscription purchase event
  Future<void> logSubscriptionPurchase(String planId, double price) async {
    await logEvent('subscription_purchase', parameters: {
      'plan_id': planId,
      'price': price,
      'currency': 'USD',
    });
  }

  /// Log ad shown event
  Future<void> logAdShown(String adType) async {
    await logEvent('ad_shown', parameters: {
      'ad_type': adType,
    });
  }

  /// Set user property
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }
}

