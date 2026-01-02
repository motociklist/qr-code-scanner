import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApphudService {
  static const String _keyIsPremium = 'is_premium';
  static const String _keyApphudUserId = 'apphud_user_id';
  static const String _apiKey = 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga';
  static const String _paywallId = 'main_paywall';

  static const MethodChannel _channel = MethodChannel('apphud_service');

  static ApphudService? _instance;
  ApphudService._();

  static ApphudService get instance {
    _instance ??= ApphudService._();
    return _instance!;
  }

  bool _isPremium = false;
  List<Map<String, dynamic>> _paywalls = [];
  List<Map<String, dynamic>> _products = [];

  bool get isPremium => _isPremium;
  List<Map<String, dynamic>> get paywalls => List.unmodifiable(_paywalls);
  List<Map<String, dynamic>> get products => List.unmodifiable(_products);

  /// Initialize Apphud
  Future<void> initialize() async {
    // Apphud doesn't support web platform
    if (kIsWeb) {
      debugPrint('Apphud is not supported on web platform');
      return;
    }

    try {
      // Get or create user ID
      final userId = await _getOrCreateUserId();

      // Initialize Apphud via method channel
      await _channel.invokeMethod('initialize', {
        'apiKey': _apiKey,
        'userId': userId,
      });

      // Load premium status
      await _loadPremiumStatus();

      // Load paywalls and products
      await _loadPaywalls();

      // Check subscription status
      await _checkSubscriptionStatus();

      // Listen to subscription changes
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (e) {
      debugPrint('Error initializing Apphud: $e');
    }
  }

  /// Handle method calls from native
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSubscriptionChanged':
        await _checkSubscriptionStatus();
        break;
      case 'onPaywallLoaded':
        await _loadPaywalls();
        break;
    }
  }

  /// Get or create Apphud user ID
  Future<String> _getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_keyApphudUserId);

    if (userId == null) {
      userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_keyApphudUserId, userId);
    }

    return userId;
  }

  /// Load premium status from local storage
  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
  }

  /// Save premium status to local storage
  Future<void> _savePremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, isPremium);
  }

  /// Check subscription status with Apphud
  Future<void> _checkSubscriptionStatus() async {
    try {
      final result = await _channel.invokeMethod('hasActiveSubscription');
      final hasActiveSubscription = result as bool? ?? false;

      final result2 = await _channel.invokeMethod('hasPremiumAccess');
      final hasPremiumAccess = result2 as bool? ?? false;

      _isPremium = hasActiveSubscription || hasPremiumAccess;
      await _savePremiumStatus(_isPremium);
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  /// Load paywalls
  Future<void> _loadPaywalls() async {
    try {
      final result = await _channel.invokeMethod('getPaywalls');
      if (result != null && result is List) {
        _paywalls = List<Map<String, dynamic>>.from(
          result.map((item) => Map<String, dynamic>.from(item as Map)),
        );

        // Extract products from paywalls
        _products = [];
        for (final paywall in _paywalls) {
          final products = paywall['products'] as List?;
          if (products != null) {
            _products.addAll(
              products.map((p) => Map<String, dynamic>.from(p as Map)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading paywalls: $e');
    }
  }

  /// Get paywall by ID
  Map<String, dynamic>? getPaywall(String paywallId) {
    try {
      return _paywalls.firstWhere((paywall) => paywall['identifier'] == paywallId);
    } catch (e) {
      return null;
    }
  }

  /// Get main paywall
  Map<String, dynamic>? getMainPaywall() {
    return getPaywall(_paywallId);
  }

  /// Get product by ID
  Map<String, dynamic>? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product['productId'] == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final result = await _channel.invokeMethod('purchaseProduct', {
        'productId': productId,
      });

      if (result != null && result is bool && result) {
        await _checkSubscriptionStatus();
        return _isPremium;
      }

      return false;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      await _channel.invokeMethod('restorePurchases');
      await _checkSubscriptionStatus();
      return _isPremium;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Set attribution data from AppsFlyer
  Future<void> setAttribution(Map<String, dynamic> attributionData) async {
    try {
      await _channel.invokeMethod('setAttribution', {
        'data': attributionData,
      });
    } catch (e) {
      debugPrint('Error setting attribution: $e');
    }
  }

  /// Check if feature is available (for premium users)
  bool canUseFeature(String feature) {
    const premiumFeatures = [
      'unlimited_scans',
      'create_qr',
      'no_ads',
      'cloud_backup',
      'advanced_analytics',
    ];

    if (!premiumFeatures.contains(feature)) {
      return true; // Feature is free
    }

    return _isPremium;
  }
}
