import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/apphud_service.dart';
import '../services/analytics_service.dart';
import '../services/appsflyer_service.dart';

enum BadgePosition { top, right }

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _selectedPlan;
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = 'weekly'; // Default selection
    _loadProducts();
  }

  /// Load products from AppHud
  Future<void> _loadProducts() async {
    if (_productsLoaded) return;

    try {
      // Refresh paywalls to ensure products are loaded
      await ApphudService.instance.refreshPaywalls();

      // Wait a bit for products to load
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _productsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7FBFF), // Very light blue
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Header with close and restore
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/subscr-page/cross.svg',
                              width: 12,
                              height: 12,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final subscriptionService = ApphudService.instance;
                          final currentContext = context;
                          final restored =
                              await subscriptionService.restorePurchases();
                          AppsFlyerService.instance
                              .logEvent('restore_purchases');
                          if (mounted && currentContext.mounted) {
                            ScaffoldMessenger.of(currentContext).showSnackBar(
                              SnackBar(
                                content: Text(restored
                                    ? 'Purchases restored successfully'
                                    : 'No purchases found to restore'),
                              ),
                            );
                            if (restored && currentContext.mounted) {
                              Navigator.pop(currentContext);
                            }
                          }
                        },
                        child: const Text(
                          'Restore',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // QR Code Icon
                  Container(
                    width: 217,
                    height: 217,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/subscr-page/qr.svg',
                        width: 165,
                        height: 165,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  const Text(
                    'Unlock Full QR Tools',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Unlimited scans, custom QR creation, and full history access.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Features list
                  _buildFeatureItem(
                    icon: 'assets/images/subscr-page/inf.svg',
                    title: 'Unlimited QR Scans',
                    description: 'Scan as many QR codes as you want',
                    iconWidth: 23,
                    iconHeight: 12,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: 'assets/images/subscr-page/color.svg',
                    title: 'Create All QR Types',
                    description: 'URL, Text, Contact, WiFi, and more',
                    iconWidth: 18,
                    iconHeight: 18,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: 'assets/images/subscr-page/shild.svg',
                    title: 'No Ads',
                    description: 'Enjoy an ad-free experience',
                    iconWidth: 17,
                    iconHeight: 18,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: 'assets/images/subscr-page/cloud.svg',
                    title: 'Cloud Backup',
                    description: 'Sync your QR codes across devices',
                    iconWidth: 22,
                    iconHeight: 16,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: 'assets/images/subscr-page/graf.svg',
                    title: 'Advanced Analytics',
                    description: 'Track scans and view detailed statistics',
                    iconWidth: 18,
                    iconHeight: 15,
                  ),
                  const SizedBox(height: 32),
                  // Pricing plans
                  _buildPricingPlan(
                    title: 'Weekly Plan',
                    price: '\$3.99',
                    period: '/ week',
                    benefit: '3-day free trial',
                    badge: 'MOST POPULAR',
                    badgeColor: const Color(0xFF7ACBFF),
                    badgeTextColor: const Color.fromARGB(255, 255, 255, 255),
                    planId: 'weekly',
                  ),
                  const SizedBox(height: 16),
                  _buildPricingPlan(
                    title: 'Monthly Plan',
                    price: '\$7.99',
                    period: '/ month',
                    benefit: 'Cancel anytime',
                    planId: 'monthly',
                  ),
                  const SizedBox(height: 16),
                  _buildPricingPlan(
                    title: 'Yearly Plan',
                    price: '\$29.99',
                    period: '/ year',
                    originalPrice: '\$99.00',
                    saveText: 'Save \$70',
                    benefit: 'Best value option',
                    badge: 'SAVE \$70',
                    badgeColor: const Color(0xFF77C97E),
                    badgeTextColor: Colors.white,
                    badgePosition: BadgePosition.right,
                    planId: 'yearly',
                  ),
                  const SizedBox(height: 32),
                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF7ACBFF), // 0% - light blue
                            Color(0xFF4DA6FF), // 100% - darker blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4DA6FF).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _selectedPlan == null
                            ? null
                            : () async {
                                if (_selectedPlan == null) return;

                                final analyticsService =
                                    AnalyticsService.instance;

                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  // Ensure products are loaded
                                  if (!_productsLoaded) {
                                    await _loadProducts();
                                  }

                                  // Map plan ID to product ID
                                  String productId;
                                  switch (_selectedPlan!.toLowerCase()) {
                                    case 'weekly':
                                      productId = ApphudService.productIdWeekly;
                                      break;
                                    case 'monthly':
                                      productId =
                                          ApphudService.productIdMonthly;
                                      break;
                                    case 'yearly':
                                      productId = ApphudService.productIdYearly;
                                      break;
                                    default:
                                      productId = _selectedPlan!;
                                  }

                                  // Try to get product - if not found, try to refresh paywalls
                                  var selectedProduct = ApphudService.instance
                                      .getProduct(productId);

                                  if (selectedProduct == null) {
                                    debugPrint(
                                        'Product not found in paywalls, refreshing...');
                                    await ApphudService.instance
                                        .refreshPaywalls();
                                    await Future.delayed(
                                        const Duration(milliseconds: 1000));
                                    selectedProduct = ApphudService.instance
                                        .getProduct(productId);
                                  }

                                  // If still not found, try async method
                                  if (selectedProduct == null) {
                                    debugPrint(
                                        'Product still not found, trying async method...');
                                    selectedProduct = await ApphudService
                                        .instance
                                        .getProductAsync(productId);
                                  }

                                  AppsFlyerService.instance.logEvent(
                                      'purchase_initiated',
                                      eventValues: {
                                        'product_id': productId,
                                      });

                                  if (selectedProduct != null) {
                                    final currentContext = context;

                                    // Check if AppHud is properly initialized
                                    if (!ApphudService.instance.isInitialized) {
                                      if (!mounted || !currentContext.mounted) {
                                        return;
                                      }
                                      Navigator.pop(
                                          currentContext); // Close loading
                                      ScaffoldMessenger.of(currentContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'AppHud is not initialized. Please check your internet connection and try again.'),
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await ApphudService.instance
                                        .purchaseSubscription(
                                      productId,
                                    );

                                    if (!mounted || !currentContext.mounted) {
                                      return;
                                    }
                                    Navigator.pop(
                                        currentContext); // Close loading

                                    if (success) {
                                      // Get price from product using getProductPrice
                                      final priceInfo = ApphudService.instance
                                          .getProductPrice(productId);
                                      final price =
                                          priceInfo?['price'] as double? ?? 0.0;
                                      final currencyCode =
                                          priceInfo?['currencyCode']
                                                  as String? ??
                                              'USD';

                                      await analyticsService
                                          .logSubscriptionPurchase(
                                        productId,
                                        price,
                                      );

                                      AppsFlyerService.instance.logEvent(
                                          'purchase_completed',
                                          eventValues: {
                                            'product_id': productId,
                                            'price': price,
                                            'currency': currencyCode,
                                          });

                                      if (!mounted || !currentContext.mounted) {
                                        return;
                                      }
                                      Navigator.pop(
                                          currentContext); // Close pricing screen
                                      ScaffoldMessenger.of(currentContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Subscription activated successfully!'),
                                        ),
                                      );
                                    } else {
                                      if (!mounted || !currentContext.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(currentContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Purchase failed. Please try again.'),
                                        ),
                                      );
                                    }
                                  } else {
                                    final currentContext = context;
                                    if (!mounted || !currentContext.mounted) {
                                      return;
                                    }
                                    Navigator.pop(
                                        currentContext); // Close loading

                                    // Check if AppHud is initialized
                                    String errorMessage;
                                    if (!ApphudService.instance.isInitialized) {
                                      errorMessage =
                                          'AppHud is not initialized. Please check your internet connection and AppHud configuration.';
                                    } else if (ApphudService
                                        .instance.paywalls.isEmpty) {
                                      errorMessage =
                                          'Products are not loaded. Please check your AppHud API key and configuration in AppHud Dashboard.';
                                    } else {
                                      errorMessage =
                                          'Product "$productId" not found. Please check that the product is configured in AppHud Dashboard and try again.';
                                    }

                                    ScaffoldMessenger.of(currentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  final currentContext = context;
                                  if (!mounted || !currentContext.mounted) {
                                    return;
                                  }
                                  Navigator.pop(
                                      currentContext); // Close loading
                                  ScaffoldMessenger.of(currentContext)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legal text
                  Text(
                    'Auto-renewable. Cancel anytime.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Terms and Privacy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
    required String description,
    required double iconWidth,
    required double iconHeight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7ACBFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                width: iconWidth,
                height: iconHeight,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingPlan({
    required String title,
    required String price,
    required String period,
    required String benefit,
    String? badge,
    Color? badgeColor,
    Color? badgeTextColor,
    BadgePosition badgePosition = BadgePosition.top,
    String? originalPrice,
    String? saveText,
    required String planId,
  }) {
    final isSelected = _selectedPlan == planId;

    return Padding(
      padding: EdgeInsets.only(
        top: badge != null && badgePosition == BadgePosition.top ? 15 : 0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card
          Container(
            padding: EdgeInsets.only(
              top:
                  badge != null && badgePosition == BadgePosition.top ? 20 : 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPlan = planId;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              period,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              originalPrice,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (saveText != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                saveText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF2196F3),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Selected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Badge on top center (for Weekly Plan) - должен быть последним чтобы быть поверх
          if (badge != null && badgePosition == BadgePosition.top)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFF7ACBFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor ?? const Color(0xFF7ACBFF),
                    ),
                  ),
                ),
              ),
            ),
          // Badge on top right (for Yearly Plan) - должен быть последним чтобы быть поверх
          if (badge != null && badgePosition == BadgePosition.right)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF77C97E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor ?? Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
