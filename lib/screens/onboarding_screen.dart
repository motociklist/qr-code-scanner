import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/navigation_helper.dart';
import '../constants/app_styles.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome',
      subtitle: 'Scan, Create & Manage QR Codes Easily',
      description: '',
      icon: Icons.qr_code_scanner,
      illustration: 'welcome',
    ),
    OnboardingPage(
      title: 'Scan QR Codes',
      subtitle: 'Quickly Scan Any QR Code',
      description: 'Align QR codes in frame and get instant results',
      icon: Icons.qr_code_scanner,
      illustration: 'scan',
    ),
    OnboardingPage(
      title: 'Create QR Codes',
      subtitle: 'Generate QR Codes Instantly',
      description: 'Enter URL, text, or contact info and get your custom QR',
      icon: Icons.qr_code,
      illustration: 'create',
    ),
    OnboardingPage(
      title: 'Manage & Share',
      subtitle: 'Save, Share, and Track All Your QR Codes',
      description: 'Access My QR Codes and History anytime',
      icon: Icons.manage_accounts,
      illustration: 'manage',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      NavigationHelper.push(context, const HomeScreen(), replace: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index == 0, index);
                },
              ),
            ),
            // Progress indicator
            _buildProgressIndicator(),
            const SizedBox(height: 20),
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7ACBFF), // 0% - light blue
                        Color(0xFF4DA6FF), // 100% - darker blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4DA6FF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: AppStyles.body.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Skip button at bottom (hidden on last page)r

            Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: AppStyles.body.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isFirstPage, int pageIndex) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 90.0,
          left: 24.0,
          right: 24.0,
          bottom: 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title first for all pages
            Text(
              page.title,
              style: AppStyles.largeTitle,
              textAlign: TextAlign.center,
            ),
            // Illustration
            _buildIllustration(page, isFirstPage),
            const SizedBox(height: 20),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 17.0, // 24 (parent) + 17 = 41px from edge
              ),
              child: Text(
                page.subtitle,
                style: AppStyles.title2,
                textAlign: TextAlign.center,
              ),
            ),
            if (page.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              // Description
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30.0, // 24 (parent) + 21 = 45px from edge
                ),
                child: Text(
                  page.description,
                  style: AppStyles.body.copyWith(
                    fontSize: 16,
                    height: 21 / 16, // line height 21 for font size 16
                    letterSpacing: -0.5,
                    color: const Color(0xFF111111),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardingPage page, bool isFirstPage) {
    switch (page.illustration) {
      case 'welcome':
        return _buildWelcomeIllustration(isFirstPage);
      case 'scan':
        return _buildScanIllustration();
      case 'create':
        return _buildCreateIllustration();
      case 'manage':
        return _buildManageIllustration();
      default:
        return _buildDefaultIllustration(page.icon);
    }
  }

  Widget _buildWelcomeIllustration(bool isFirstPage) {
    return SizedBox(
      height: isFirstPage ? 350 : 300,
      width: double.infinity,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/freepik__create-a-clear-scanning-composition-where-the-main__5227 1.svg',
          fit: BoxFit.contain,
          width: double.infinity,
          height: isFirstPage ? 350 : 300,
          placeholderBuilder: (context) => const SizedBox(
            width: double.infinity,
            height: 350,
          ),
        ),
      ),
    );
  }

  Widget _buildScanIllustration() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/images/onbord2qr.png',
          fit: BoxFit.contain,
          width: double.infinity,
          height: 320,
        ),
      ),
    );
  }

  Widget _buildCreateIllustration() {
    return Container(
      height: 340,
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 0,
        left: 40,
        right: 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Website URL',
              style: TextStyle(
                fontSize: 13.08,
                fontWeight: FontWeight.w500, // Medium
                letterSpacing: -0.44,
                color: Color(0xFF111111),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'https://example.com',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/images/board3-link.svg',
                  width: 17,
                  height: 13,
                  fit: BoxFit.contain,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF9E9E9E),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // QR code image

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7ACBFF), // 0% - light blue
                    Color(0xFF4DA6FF), // 100% - darker blue
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4DA6FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  'Generate QR Code',
                  style: AppStyles.body.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SvgPicture.asset(
              'assets/images/board3-qr.svg',
              width: 153,
              height: 153,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildManageIllustration() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/images/board4.png',
          fit: BoxFit.contain,
          width: double.infinity,
          height: 320,
        ),
      ),
    );
  }

  Widget _buildDefaultIllustration(IconData icon) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 120,
          color: Colors.blue[400],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? Colors.blue[400]! // Light blue for active indicator
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String illustration;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.illustration,
  });
}
