import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';

enum BadgePosition { top, right }

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50]!.withValues(alpha: 0.5),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue[50]!.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header with close and restore
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement restore purchases
                          },
                          child: const Text(
                            'Restore',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // QR Code Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        size: 60,
                        color: Colors.blue[400],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    const Text(
                      'Unlock Full QR Tools',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Features list
                    const FeatureCard(
                      icon: Icons.all_inclusive,
                      title: 'Unlimited QR Scans',
                      description: 'Scan as many QR codes as you want',
                    ),
                    const SizedBox(height: 16),
                    const FeatureCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Create All QR Types',
                      description: 'URL, Text, Contact, WiFi, and more',
                    ),
                    const SizedBox(height: 16),
                    const FeatureCard(
                      icon: Icons.shield,
                      title: 'No Ads',
                      description: 'Enjoy an ad-free experience',
                    ),
                    const SizedBox(height: 16),
                    const FeatureCard(
                      icon: Icons.cloud,
                      title: 'Cloud Backup',
                      description: 'Sync your QR codes across devices',
                    ),
                    const SizedBox(height: 16),
                    const FeatureCard(
                      icon: Icons.analytics,
                      title: 'Advanced Analytics',
                      description: 'Track scans and view detailed statistics',
                    ),
                    const SizedBox(height: 40),
                    // Pricing plans
                    _buildPricingPlan(
                      title: 'Weekly Plan',
                      price: '\$3.99',
                      period: '/ week',
                      benefit: '3-day free trial',
                      badge: 'MOST POPULAR',
                      badgeColor: Colors.blue[100]!,
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
                      originalPrice: '\$99.99',
                      benefit: 'Best value option',
                      badge: 'SAVE \$70',
                      badgeColor: Colors.green[100]!,
                      badgePosition: BadgePosition.right,
                      planId: 'yearly',
                    ),
                    const SizedBox(height: 32),
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPlan == null
                            ? null
                            : () {
                                // TODO: Implement purchase
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
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
                          onPressed: () {
                            // TODO: Open Terms of Service
                          },
                          child: Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
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
                          onPressed: () {
                            // TODO: Open Privacy Policy
                          },
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
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
          ],
        ),
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
    BadgePosition badgePosition = BadgePosition.top,
    String? originalPrice,
    required String planId,
  }) {
    final isSelected = _selectedPlan == planId;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPlan = planId;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null && badgePosition == BadgePosition.top) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
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
                            Text(
                              originalPrice,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badge != null && badgePosition == BadgePosition.right)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor ?? Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                  ],
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[400],
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
      ],
    );
  }
}

