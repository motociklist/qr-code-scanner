import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'apphud_service.dart';
import 'ads_service.dart';
import 'analytics_service.dart';
import 'appsflyer_service.dart';
import 'att_service.dart';
import 'history_service.dart';
import 'saved_qr_service.dart';

/// Centralized service initialization to reduce code duplication in main.dart
class AppInitializer {
  /// Initialize all app services
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred orientations (not for web)
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Initialize Firebase (skip on web if not configured)
    await _initializeFirebase();

    // Initialize mobile-only services
    if (!kIsWeb) {
      await _initializeMobileServices();
    }

    // Initialize Analytics
    await _initializeAnalytics();

    // Load history and saved QR codes
    await _loadHistory();
    await _loadSavedQRCodes();
  }

  static Future<void> _initializeFirebase() async {
    if (!kIsWeb || DefaultFirebaseOptions.isConfigured) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Error initializing Firebase: $e');
      }
    } else {
      debugPrint(
          'Firebase web configuration not set up. Skipping initialization.');
    }
  }

  static Future<void> _initializeMobileServices() async {
    // Request ATT permission (iOS only)
    try {
      final attStatus = await ATTService.instance.requestPermission();
      debugPrint('ATT Status: $attStatus');
    } catch (e) {
      debugPrint('Error requesting ATT: $e');
    }

    // Initialize services in parallel to speed up startup
    // Don't wait for Apphud to complete - it shouldn't block app startup
    _initializeService(
      'Apphud',
      () => ApphudService.instance.initialize(),
    ).catchError((e) {
      debugPrint('Apphud initialization error (non-blocking): $e');
    });

    // Initialize AppsFlyer (will send attribution to Apphud)
    await _initializeService(
      'AppsFlyer',
      () => AppsFlyerService.instance.initialize(),
    );

    // Initialize Google Mobile Ads
    await _initializeService(
      'Google Mobile Ads',
      () => AdsService.instance.initialize(),
    );

    // Update ATT status in AppsFlyer
    try {
      final attStatus = await ATTService.instance.getStatus();
      await AppsFlyerService.instance.updateATTStatus(attStatus);
    } catch (e) {
      debugPrint('Error updating ATT status: $e');
    }

    // Set up attribution integration
    await _setupAttribution();
  }

  /// Set up attribution integration between services
  static Future<void> _setupAttribution() async {
    try {
      // Firebase attribution data (if available)
      // Note: Firebase doesn't provide direct attribution API in Flutter
      // You may need to use Firebase Dynamic Links or App Check for attribution
      // For now, we'll set up the structure for future integration

      // Apple Search Ads attribution (iOS only)
      // Note: Apple Search Ads attribution typically requires native implementation
      // This is a placeholder for future integration

      debugPrint('Attribution integration set up');
    } catch (e) {
      debugPrint('Error setting up attribution: $e');
    }
  }

  static Future<void> _initializeAnalytics() async {
    if (!kIsWeb || DefaultFirebaseOptions.isConfigured) {
      await _initializeService(
        'Firebase Analytics',
        () => AnalyticsService.instance.initialize(),
      );
    } else {
      debugPrint('Firebase Analytics skipped: web configuration not set up.');
    }
  }

  static Future<void> _loadHistory() async {
    await _initializeService(
      'History',
      () => HistoryService().loadHistory(),
    );
  }

  static Future<void> _loadSavedQRCodes() async {
    await _initializeService(
      'Saved QR Codes',
      () => SavedQRService.instance.loadSavedCodes(),
    );
  }

  static Future<void> _initializeService(
    String serviceName,
    Future<void> Function() initFunction,
  ) async {
    try {
      await initFunction();
    } catch (e) {
      debugPrint('Error initializing $serviceName: $e');
    }
  }
}

