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
                  return _buildPage(_pages[index], index == 0);
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
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7ACBFF), // 0% - light blue
                        const Color(0xFF4DA6FF), // 100% - darker blue
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
            // Skip button at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
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

  Widget _buildPage(OnboardingPage page, bool isFirstPage) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirstPage ? 90.0 : 24.0,
          left: 24.0,
          right: 24.0,
          bottom: 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFirstPage)
              Text(
                page.title,
                style: AppStyles.largeTitle,
                textAlign: TextAlign.center,
              ),
            if (isFirstPage) const SizedBox(height: 15),
            // Illustration
            _buildIllustration(page, isFirstPage),
            if (!isFirstPage) const SizedBox(height: 40),
            // Title (for other pages)
            if (!isFirstPage)
              Text(
                page.title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            if (!isFirstPage) const SizedBox(height: 16),
            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isFirstPage ? 20.0 : 0.0,
              ),
              child: Text(
                page.subtitle,
                style: AppStyles.title2,
                textAlign: TextAlign.center,
              ),
            ),
            if (page.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Description
              Text(
                page.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }

  Widget _buildScanIllustration() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: Center(
        child: SvgPicture.asset(
          'assets/images/board2.svg',
          fit: BoxFit.contain,
          width: double.infinity,
          height: 300,
        ),
      ),
    );
  }

  Widget _buildCreateIllustration() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  Icon(Icons.link, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 10),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Generate button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[400]!,
                    Colors.blue[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Generate QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // QR code result
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 60,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageIllustration() {
    return SizedBox(
      height: 300,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 4,
        itemBuilder: (context, index) {
          return _buildQRCard(index);
        },
      ),
    );
  }

  Widget _buildQRCard(int index) {
    final titles = ['My Website', 'Contact Info', 'My Website', 'Contact Info'];
    final subtitles = [
      'portfolio.com',
      'John Doe vCard',
      'portfolio.com',
      'John Doe vCard'
    ];
    final dates = [
      'Dec 15, 2024',
      'Dec 12, 2024',
      'Dec 15, 2024',
      'Dec 12, 2024'
    ];
    final views = [67, 12, 67, 12];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titles[index],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitles[index],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dates[index],
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${views[index]}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
