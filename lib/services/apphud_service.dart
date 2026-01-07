import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:apphud/apphud.dart';
import 'package:apphud/models/apphud_models/apphud_paywall.dart';
import 'package:apphud/models/apphud_models/apphud_placement.dart';
import 'package:apphud/models/apphud_models/apphud_user.dart';
import 'package:apphud/models/apphud_models/apphud_subscription.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import 'package:apphud/models/apphud_models/apphud_paywalls.dart';
import 'package:apphud/models/apphud_models/composite/apphud_purchase_result.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_data.dart';
import 'package:apphud/models/apphud_models/apphud_attribution_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Custom ApphudListener implementation
class _ApphudListenerImpl extends ApphudListener {
  final Function(List<ApphudPaywall>)? onPaywallsUpdated;
  final Function(List<ApphudSubscriptionWrapper>)? onSubscriptionsUpdated;
  final Function(ApphudUser)? onUserUpdated;
  _ApphudListenerImpl({
    this.onPaywallsUpdated,
    this.onSubscriptionsUpdated,
    this.onUserUpdated,
  });

  @override
  Future<void> apphudDidChangeUserID(String userId) async {}

  @override
  Future<void> apphudDidFecthProducts(List products) async {}

  @override
  Future<void> paywallsDidFullyLoad(ApphudPaywalls paywalls) async {
    onPaywallsUpdated?.call(paywalls.paywalls);
  }

  @override
  Future<void> userDidLoad(ApphudUser user) async {
    onUserUpdated?.call(user);
  }

  @override
  Future<void> apphudSubscriptionsUpdated(
    List<ApphudSubscriptionWrapper> subscriptions,
  ) async {
    onSubscriptionsUpdated?.call(subscriptions);
  }

  @override
  Future<void> apphudNonRenewingPurchasesUpdated(List purchases) async {
    // Non-renewing purchases updated - no action needed
  }

  @override
  Future<void> placementsDidFullyLoad(List<ApphudPlacement> placements) async {}

  @override
  Future<void> apphudDidReceivePurchase(purchase) async {}
}

class ApphudService {
  static const String _keyIsPremium = 'is_premium';
  static const String _keyApphudUserId = 'apphud_user_id';
  static const String _apiKey = 'app_Z44sHCCXqhP5FCBDa8SxKBLB7VLpga';
  static const String _paywallId = 'main_paywall';

  // Product IDs
  static const String productIdWeekly = 'sonicforge_weekly';
  static const String productIdMonthly = 'sonicforge_monthly';
  static const String productIdYearly = 'sonicforge_yearly';

  static ApphudService? _instance;
  ApphudService._();

  static ApphudService get instance {
    _instance ??= ApphudService._();
    return _instance!;
  }

  bool _isPremium = false;
  bool _isInitialized = false;
  List<ApphudPaywall> _paywalls = [];
  List<ApphudPlacement> _placements = [];
  ApphudUser? _user;
  ApphudSubscriptionWrapper? _activeSubscription;

  // Listeners
  final List<Function()> _subscriptionListeners = [];
  final List<Function(List<ApphudPaywall>)> _paywallListeners = [];

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;
  List<ApphudPaywall> get paywalls => List.unmodifiable(_paywalls);
  List<ApphudPlacement> get placements => List.unmodifiable(_placements);
  ApphudUser? get user => _user;
  ApphudSubscriptionWrapper? get activeSubscription => _activeSubscription;

  /// Initialize Apphud
  Future<void> initialize({String? userId}) async {
    // Apphud doesn't support web platform
    if (kIsWeb) {
      debugPrint('Apphud is not supported on web platform');
      return;
    }

    if (_isInitialized) {
      debugPrint('Apphud is already initialized');
      return;
    }

    try {
      // Check if Apphud SDK is already initialized (e.g., after hot restart)
      try {
        final existingUserId = await Apphud.userID().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            throw TimeoutException('Apphud userID check timeout');
          },
        );
        debugPrint(
            'Apphud SDK already initialized with user ID: $existingUserId');
        // SDK is already initialized, just restore state
        await _restoreApphudState().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Apphud state restoration timeout');
          },
        );
        _isInitialized = true;
        return;
      } catch (e) {
        // SDK is not initialized, proceed with initialization
        debugPrint('Apphud SDK not initialized, starting initialization...');
      }

      // Get or create user ID
      final apphudUserId = userId ?? await _getOrCreateUserId();

      // Initialize Apphud with timeout
      _user = await Apphud.start(
        apiKey: _apiKey,
        userID: apphudUserId,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Apphud initialization timeout');
          throw TimeoutException('Apphud initialization timeout');
        },
      );

      // Set up listener for subscription and paywall changes
      await Apphud.setListener(
        listener: _ApphudListenerImpl(
          onPaywallsUpdated: (paywalls) {
            debugPrint('Apphud paywalls updated: ${paywalls.length} paywalls');
            _paywalls = paywalls;
            _notifyPaywallListeners();
          },
          onSubscriptionsUpdated: (subscriptions) {
            debugPrint(
                'Apphud subscriptions updated: ${subscriptions.length} subscriptions');
            _updateSubscriptionStatus(subscriptions);
            _notifySubscriptionListeners();
          },
          onUserUpdated: (user) {
            debugPrint('Apphud user updated: ${user.userId}');
            _user = user;
            _updateSubscriptionStatus(user.subscriptions);
          },
        ),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Apphud setListener timeout');
        },
      );

      // Load initial data with timeouts to prevent blocking
      await _loadPaywalls().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Loading paywalls timeout');
        },
      );
      await _loadPlacements().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Loading placements timeout');
        },
      );
      await _checkSubscriptionStatus().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Checking subscription status timeout');
        },
      );

      _isInitialized = true;
      debugPrint('Apphud initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Apphud: $e');
      // Don't block app startup if Apphud fails to initialize
      // Mark as initialized anyway to prevent retry loops
      _isInitialized = true;
    }
  }

  /// Restore Apphud state after hot restart
  Future<void> _restoreApphudState() async {
    try {
      // Set up listener again (it might have been lost during hot restart)
      await Apphud.setListener(
        listener: _ApphudListenerImpl(
          onPaywallsUpdated: (paywalls) {
            debugPrint('Apphud paywalls updated: ${paywalls.length} paywalls');
            _paywalls = paywalls;
            _notifyPaywallListeners();
          },
          onSubscriptionsUpdated: (subscriptions) {
            debugPrint(
                'Apphud subscriptions updated: ${subscriptions.length} subscriptions');
            _updateSubscriptionStatus(subscriptions);
            _notifySubscriptionListeners();
          },
          onUserUpdated: (user) {
            debugPrint('Apphud user updated: ${user.userId}');
            _user = user;
            _updateSubscriptionStatus(user.subscriptions);
          },
        ),
      );

      // Load current data
      await _loadPaywalls();
      await _loadPlacements();
      await _checkSubscriptionStatus();

      debugPrint('Apphud state restored successfully');
    } catch (e) {
      debugPrint('Error restoring Apphud state: $e');
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

  /// Update subscription status
  void _updateSubscriptionStatus(
      List<ApphudSubscriptionWrapper> subscriptions) {
    // Find active subscription
    try {
      _activeSubscription = subscriptions.firstWhere((sub) => sub.isActive);
    } catch (e) {
      _activeSubscription =
          subscriptions.isNotEmpty ? subscriptions.first : null;
    }

    // Check if user has active subscription
    final wasPremium = _isPremium;
    _isPremium = subscriptions.any((sub) => sub.isActive);

    // Save premium status
    if (wasPremium != _isPremium) {
      _savePremiumStatus(_isPremium);
    }
  }

  /// Save premium status to local storage
  Future<void> _savePremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, isPremium);
  }

  /// Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    try {
      // Check subscription status from user data
      if (_user != null) {
        final subscriptions = _user!.subscriptions;
        _isPremium = subscriptions.any((sub) => sub.isActive);
        await _savePremiumStatus(_isPremium);
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  /// Load paywalls
  Future<void> _loadPaywalls() async {
    try {
      final paywallsResult = await Apphud.paywallsDidLoadCallback().timeout(
        const Duration(seconds: 10),
      );
      _paywalls = paywallsResult.paywalls;
      debugPrint('Loaded ${_paywalls.length} paywalls');

      if (_paywalls.isEmpty) {
        debugPrint('WARNING: No paywalls loaded. This may indicate:');
        debugPrint('1. API key is incorrect or inactive');
        debugPrint('2. App is not properly configured in AppHud Dashboard');
        debugPrint('3. Network connectivity issues');
        debugPrint('4. AppHud service is temporarily unavailable');
      }

      _notifyPaywallListeners();
    } on TimeoutException {
      debugPrint('Timeout loading paywalls');
      _paywalls = [];
    } catch (e) {
      debugPrint('Error loading paywalls: $e');
      _paywalls = [];
    }
  }

  /// Load placements
  Future<void> _loadPlacements() async {
    try {
      _placements = await Apphud.placements();
      debugPrint('Loaded ${_placements.length} placements');
    } catch (e) {
      debugPrint('Error loading placements: $e');
    }
  }

  /// Get paywall by ID
  ApphudPaywall? getPaywall(String paywallId) {
    try {
      return _paywalls.firstWhere((paywall) => paywall.identifier == paywallId);
    } catch (e) {
      return null;
    }
  }

  /// Get main paywall
  ApphudPaywall? getMainPaywall() {
    return getPaywall(_paywallId);
  }

  /// Get placement by identifier
  ApphudPlacement? getPlacement(String placementId) {
    try {
      return _placements
          .firstWhere((placement) => placement.identifier == placementId);
    } catch (e) {
      return null;
    }
  }

  /// Get product by ID from paywalls
  ApphudProduct? getProduct(String productId) {
    // First, try to find product in loaded paywalls
    for (final paywall in _paywalls) {
      final products = paywall.products ?? [];
      try {
        return products.firstWhere((product) => product.productId == productId);
      } catch (e) {
        continue;
      }
    }

    // If not found in paywalls, try to get from placements
    for (final placement in _placements) {
      final paywall = placement.paywall;
      if (paywall != null) {
        final products = paywall.products ?? [];
        try {
          return products
              .firstWhere((product) => product.productId == productId);
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  /// Get product by ID with refresh (fallback method)
  Future<ApphudProduct?> getProductAsync(String productId) async {
    try {
      // First try the cached method
      final cachedProduct = getProduct(productId);
      if (cachedProduct != null) {
        return cachedProduct;
      }

      // If not found, refresh paywalls and try again
      debugPrint(
          'Product not found in cache, refreshing paywalls for: $productId');
      await refreshPaywalls();
      await Future.delayed(const Duration(milliseconds: 500));

      return getProduct(productId);
    } catch (e) {
      debugPrint('Error getting product async: $e');
    }

    return null;
  }

  /// Get product price and currency
  Map<String, dynamic>? getProductPrice(String productId) {
    final product = getProduct(productId);
    if (product == null) return null;

    try {
      // For iOS - use ApphudProduct.skProduct.price and priceLocale.currencyCode
      if (product.skProduct != null) {
        final skProduct = product.skProduct!;
        final price = skProduct.price;
        final currencyCode = skProduct.priceLocale.currencyCode;

        return {
          'price': price,
          'currencyCode': currencyCode,
          'locale': skProduct.priceLocale.toString(),
        };
      }

      // For Android
      if (product.productDetails != null) {
        final productDetails = product.productDetails!;
        final price = productDetails
                    .oneTimePurchaseOfferDetails?.priceAmountMicros !=
                null
            ? productDetails.oneTimePurchaseOfferDetails!.priceAmountMicros /
                1000000
            : (productDetails.subscriptionOfferDetails?.isNotEmpty ?? false)
                ? productDetails.subscriptionOfferDetails!.first.pricingPhases
                        .first.priceAmountMicros /
                    1000000
                : 0.0;

        return {
          'price': price,
          'currencyCode':
              productDetails.oneTimePurchaseOfferDetails?.priceCurrencyCode ??
                  productDetails.subscriptionOfferDetails?.first.pricingPhases
                      .first.priceCurrencyCode,
          'priceString':
              productDetails.oneTimePurchaseOfferDetails?.formattedPrice ??
                  productDetails.subscriptionOfferDetails?.first.pricingPhases
                      .first.formattedPrice,
        };
      }
    } catch (e) {
      debugPrint('Error getting product price: $e');
    }

    return null;
  }

  /// Get all products from a paywall
  List<ApphudProduct> getProductsFromPaywall(String paywallId) {
    final paywall = getPaywall(paywallId);
    if (paywall == null) return [];
    return paywall.products ?? [];
  }

  /// Get all products from main paywall
  List<ApphudProduct> getProductsFromMainPaywall() {
    return getProductsFromPaywall(_paywallId);
  }

  /// Get product by plan ID (maps plan IDs to product IDs)
  ApphudProduct? getProductByPlanId(String planId) {
    String productId;
    switch (planId.toLowerCase()) {
      case 'weekly':
        productId = productIdWeekly;
        break;
      case 'monthly':
        productId = productIdMonthly;
        break;
      case 'yearly':
        productId = productIdYearly;
        break;
      default:
        productId = planId; // Use planId as productId if not recognized
    }
    return getProduct(productId);
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    try {
      // Check if AppHud is initialized
      if (!_isInitialized) {
        debugPrint('AppHud is not initialized, attempting to initialize...');
        await initialize();
        if (!_isInitialized) {
          debugPrint('Failed to initialize AppHud');
          return false;
        }
      }

      // Check if paywalls are loaded
      if (_paywalls.isEmpty) {
        debugPrint('Paywalls are empty, attempting to load...');
        await refreshPaywalls();
        if (_paywalls.isEmpty) {
          debugPrint(
              'Failed to load paywalls. Check AppHud API key and configuration.');
          return false;
        }
      }

      // Try to get product from cache first
      var product = getProduct(productId);

      // If not found, try async method
      if (product == null) {
        debugPrint(
            'Product not found in cache, trying async method: $productId');
        product = await getProductAsync(productId);
      }

      // If still not found, try refreshing paywalls and getting again
      if (product == null) {
        debugPrint('Product still not found, refreshing paywalls: $productId');
        await refreshPaywalls();
        await Future.delayed(const Duration(milliseconds: 1000));
        product = getProduct(productId);
      }

      if (product == null) {
        debugPrint('Product not found after all attempts: $productId');
        debugPrint('Available paywalls: ${_paywalls.length}');
        for (final paywall in _paywalls) {
          debugPrint(
              'Paywall ${paywall.identifier} has ${paywall.products?.length ?? 0} products');
          if (paywall.products != null) {
            for (final p in paywall.products!) {
              debugPrint('  - Product ID: ${p.productId}');
            }
          }
        }
        return false;
      }

      final result = await Apphud.purchase(product: product).timeout(
        const Duration(seconds: 30),
      );

      if (result.error == null) {
        // Refresh subscription status
        await _checkSubscriptionStatus();
        _notifySubscriptionListeners();
        return true;
      }

      if (result.error != null) {
        debugPrint('Purchase error: ${result.error}');
      }

      return false;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  /// Purchase subscription and return result
  Future<ApphudPurchaseResult?> purchaseSubscriptionWithResult(
      String productId) async {
    try {
      final product = getProduct(productId);
      if (product == null) {
        debugPrint('Product not found: $productId');
        return null;
      }

      final result = await Apphud.purchase(product: product);

      if (result.error == null) {
        // Refresh subscription status
        await _checkSubscriptionStatus();
        _notifySubscriptionListeners();
      }

      return result;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return null;
    }
  }

  /// Purchase product from paywall
  Future<ApphudPurchaseResult?> purchaseProduct(ApphudProduct product) async {
    try {
      final result = await Apphud.purchase(product: product);

      if (result.error == null) {
        // Refresh subscription status
        await _checkSubscriptionStatus();
      }

      return result;
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      return null;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final result = await Apphud.restorePurchases();

      // Convert ApphudSubscriptionWrapper to List for update
      _updateSubscriptionStatus(result.subscriptions);
      await _savePremiumStatus(_isPremium);
      _notifySubscriptionListeners();

      // Return true if we have active subscriptions
      return hasActiveSubscription();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Refresh paywalls and placements
  Future<void> refreshPaywalls() async {
    await _loadPaywalls();
  }

  /// Refresh placements
  Future<void> refreshPlacements() async {
    await _loadPlacements();
  }

  /// Refresh all data (user, paywalls, placements, subscription status)
  Future<void> refreshAll() async {
    await _loadPaywalls();
    await _loadPlacements();
    await _checkSubscriptionStatus();
  }

  /// Check if user has active subscription
  bool hasActiveSubscription() {
    if (_user == null) return false;
    final subscriptions = _user!.subscriptions;
    return subscriptions.any((sub) => sub.isActive);
  }

  /// Check if user has premium access
  bool hasPremiumAccess() {
    return hasActiveSubscription();
  }

  /// Set attribution data
  Future<void> setAttribution({
    Map<String, dynamic>? appsFlyerData,
    Map<String, dynamic>? firebaseData,
    Map<String, dynamic>? appleSearchAdsData,
  }) async {
    if (kIsWeb || !_isInitialized) {
      debugPrint('Apphud not initialized, skipping attribution');
      return;
    }

    try {
      // Set AppsFlyer attribution
      if (appsFlyerData != null && appsFlyerData.isNotEmpty) {
        final attributionData = ApphudAttributionData(
          rawData: appsFlyerData,
        );
        await Apphud.setAttribution(
          provider: ApphudAttributionProvider.appsFlyer,
          data: attributionData,
        );
        debugPrint(
            'AppsFlyer attribution set: ${appsFlyerData.keys.join(", ")}');
      }

      // Set Firebase attribution
      if (firebaseData != null && firebaseData.isNotEmpty) {
        final attributionData = ApphudAttributionData(
          rawData: firebaseData,
        );
        await Apphud.setAttribution(
          provider: ApphudAttributionProvider.firebase,
          data: attributionData,
        );
        debugPrint('Firebase attribution set: ${firebaseData.keys.join(", ")}');
      }

      // Set Apple Search Ads attribution
      if (appleSearchAdsData != null && appleSearchAdsData.isNotEmpty) {
        final attributionData = ApphudAttributionData(
          rawData: appleSearchAdsData,
        );
        await Apphud.setAttribution(
          provider: ApphudAttributionProvider.appleAdsAttribution,
          data: attributionData,
        );
        debugPrint(
            'Apple Search Ads attribution set: ${appleSearchAdsData.keys.join(", ")}');
      }
    } catch (e) {
      debugPrint('Error setting attribution: $e');
    }
  }

  /// Set attribution from AppsFlyer (legacy method for compatibility)
  Future<void> setAttributionFromAppsFlyer(
      Map<String, dynamic> attributionData) async {
    await setAttribution(appsFlyerData: attributionData);
  }

  /// Add subscription listener
  void addSubscriptionListener(Function() listener) {
    _subscriptionListeners.add(listener);
  }

  /// Remove subscription listener
  void removeSubscriptionListener(Function() listener) {
    _subscriptionListeners.remove(listener);
  }

  /// Add paywall listener
  void addPaywallListener(Function(List<ApphudPaywall>) listener) {
    _paywallListeners.add(listener);
  }

  /// Remove paywall listener
  void removePaywallListener(Function(List<ApphudPaywall>) listener) {
    _paywallListeners.remove(listener);
  }

  /// Notify subscription listeners
  void _notifySubscriptionListeners() {
    for (final listener in _subscriptionListeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error in subscription listener: $e');
      }
    }
  }

  /// Notify paywall listeners
  void _notifyPaywallListeners() {
    for (final listener in _paywallListeners) {
      try {
        listener(_paywalls);
      } catch (e) {
        debugPrint('Error in paywall listener: $e');
      }
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

  /// Get subscription status details
  Map<String, dynamic> getSubscriptionStatus() {
    return {
      'isPremium': _isPremium,
      'hasActiveSubscription': hasActiveSubscription(),
      'hasPremiumAccess': hasPremiumAccess(),
      'activeSubscription': _activeSubscription != null
          ? {
              'productId': _activeSubscription!.productId,
              'expiresAt': _activeSubscription!.expiresAt,
              'status': _activeSubscription!.status.toString(),
            }
          : null,
    };
  }

  /// Get all subscriptions (active and inactive)
  List<ApphudSubscriptionWrapper> getAllSubscriptions() {
    return _user?.subscriptions ?? [];
  }

  /// Get active subscriptions only
  List<ApphudSubscriptionWrapper> getActiveSubscriptions() {
    if (_user == null) return [];
    return _user!.subscriptions.where((sub) => sub.isActive).toList();
  }

  /// Check subscription status for a specific product
  bool hasSubscriptionForProduct(String productId) {
    final subscriptions = _user?.subscriptions ?? [];
    return subscriptions
        .any((sub) => sub.productId == productId && sub.isActive);
  }
}
