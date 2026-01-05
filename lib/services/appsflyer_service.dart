import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'apphud_service.dart';
import 'att_service.dart';

// Conditional import for Platform - only works on mobile
import 'dart:io' if (dart.library.html) 'dart:html' as io;

// Helper to check if platform is iOS (only works on mobile)
bool _isIOS() {
  if (kIsWeb) return false;
  // On web, io will be dart:html which doesn't have Platform
  // On mobile, io will be dart:io which has Platform.isIOS
  try {
    // ignore: avoid_dynamic_calls
    return (io.Platform as dynamic).isIOS == true;
  } catch (e) {
    // On web, Platform doesn't exist, so return false
    return false;
  }
}

class AppsFlyerService {
  static const String _devKey = 'GAgckFyN4yETigBtP4qtRG';
  static const String _appleAppId = '6749377146';
  static const int _attWaitTime = 60; // seconds

  static AppsFlyerService? _instance;
  AppsFlyerService._();

  static AppsFlyerService get instance {
    _instance ??= AppsFlyerService._();
    return _instance!;
  }

  AppsflyerSdk? _appsflyerSdk;
  bool _isInitialized = false;

  /// Initialize AppsFlyer
  Future<void> initialize() async {
    if (_isInitialized) return;

    // AppsFlyer doesn't support web platform
    if (kIsWeb) {
      debugPrint('AppsFlyer is not supported on web platform');
      return;
    }

    try {
      final appsflyerOptions = AppsFlyerOptions(
        afDevKey: _devKey,
        showDebug: false,
        timeToWaitForATTUserAuthorization: _attWaitTime.toDouble(),
        appId: _isIOS() ? _appleAppId : '',
      );

      _appsflyerSdk = AppsflyerSdk(appsflyerOptions);

      // Set conversion callback
      _appsflyerSdk!.onInstallConversionData((data) {
        _handleConversionData(data);
      });

      // Set deep link callback
      _appsflyerSdk!.onDeepLinking((data) {
        try {
          // Handle deep link - DeepLinkResult structure varies by version
          // For now, we'll handle it safely
          debugPrint('Deep link received: $data');
          // Deep link handling can be implemented when needed
        } catch (e) {
          debugPrint('Error in deep link callback: $e');
        }
      });

      // Start AppsFlyer
      await _appsflyerSdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      // Wait for ATT authorization on iOS
      if (_isIOS()) {
        await _waitForATT();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing AppsFlyer: $e');
    }
  }

  /// Wait for ATT authorization
  Future<void> _waitForATT() async {
    try {
      final attStatus = await ATTService.instance.getStatus();

      if (attStatus == ATTStatus.authorized) {
        // Set IDFA in AppsFlyer
        final idfa = await ATTService.instance.getIDFA();
        if (idfa != null) {
          _appsflyerSdk?.setCustomerUserId(idfa);
        }
      }
    } catch (e) {
      debugPrint('Error waiting for ATT: $e');
    }
  }

  /// Handle conversion data
  void _handleConversionData(Map<dynamic, dynamic> data) {
    try {
      // Convert to Map<String, dynamic>
      final attributionData = <String, dynamic>{};
      data.forEach((key, value) {
        attributionData[key.toString()] = value;
      });

      // Send attribution to Apphud
      ApphudService.instance.setAttribution(
        appsFlyerData: attributionData,
      );

      debugPrint('AppsFlyer conversion data: $attributionData');
    } catch (e) {
      debugPrint('Error handling conversion data: $e');
    }
  }


  /// Log event
  Future<void> logEvent(String eventName, {Map<String, dynamic>? eventValues}) async {
    try {
      _appsflyerSdk?.logEvent(eventName, eventValues ?? {});
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  /// Set user ID
  Future<void> setCustomerUserId(String userId) async {
    try {
      _appsflyerSdk?.setCustomerUserId(userId);
    } catch (e) {
      debugPrint('Error setting customer user ID: $e');
    }
  }

  /// Update ATT status
  Future<void> updateATTStatus(ATTStatus status) async {
    if (kIsWeb) return; // Not supported on web
    if (_isIOS() && status == ATTStatus.authorized) {
      try {
        final idfa = await ATTService.instance.getIDFA();
        if (idfa != null && idfa.isNotEmpty) {
          _appsflyerSdk?.setCustomerUserId(idfa);
        }
      } catch (e) {
        debugPrint('Error updating ATT status: $e');
      }
    }
  }
}

