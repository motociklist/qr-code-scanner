import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/apphud_service.dart';
import 'services/ads_service.dart';
import 'services/analytics_service.dart';
import 'services/appsflyer_service.dart';
import 'services/att_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (not for web)
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue without Firebase if initialization fails
  }

  // Initialize mobile-only services
  if (!kIsWeb) {
    // Request ATT permission (iOS only)
    try {
      final attStatus = await ATTService.instance.requestPermission();
      debugPrint('ATT Status: $attStatus');
    } catch (e) {
      debugPrint('Error requesting ATT: $e');
    }

    // Initialize mobile services
    try {
      await ApphudService.instance.initialize();
    } catch (e) {
      debugPrint('Error initializing Apphud: $e');
    }

    try {
      await AppsFlyerService.instance.initialize();
    } catch (e) {
      debugPrint('Error initializing AppsFlyer: $e');
    }

    try {
      await AdsService.instance.initialize();
    } catch (e) {
      debugPrint('Error initializing Google Mobile Ads: $e');
    }

    // Update ATT status in AppsFlyer
    try {
      final attStatus = await ATTService.instance.getStatus();
      await AppsFlyerService.instance.updateATTStatus(attStatus);
    } catch (e) {
      debugPrint('Error updating ATT status: $e');
    }
  }

  // Initialize Analytics (works on web too)
  try {
    await AnalyticsService.instance.initialize();
  } catch (e) {
    debugPrint('Error initializing Firebase Analytics: $e');
  }

  runApp(const QRCodeScannerApp());
}

class QRCodeScannerApp extends StatelessWidget {
  const QRCodeScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Master',
      debugShowCheckedModeBanner: false,
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ru', ''),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FC3F7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
