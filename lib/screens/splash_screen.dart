import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Navigate to appropriate screen after 3 seconds
    Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => onboardingCompleted
                ? const HomeScreen()
                : const OnboardingScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background elements
          _buildBackgroundDecorations(),
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    // App Icon
                    _buildAppIcon(),
                    const SizedBox(height: 24),
                    // App Name
                    const Text(
                      'QR Master',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tagline
                    const Text(
                      'Scan • Create • Manage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading indicator
                    _buildLoadingIndicator(),
                    const SizedBox(height: 12),
                    // Loading text
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Version info at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Large orange/yellow circle - top right
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFE5B4).withValues(alpha: 0.3),
            ),
          ),
        ),
        // Small blue circle with dot - below orange
        Positioned(
          top: 120,
          right: 40,
          child: Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB3E5FC).withValues(alpha: 0.3),
                ),
              ),
              Positioned(
                left: -10,
                top: 30,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Small orange dot - mid left
        Positioned(
          top: 200,
          left: 40,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF9800),
            ),
          ),
        ),
        // Small green dot - below orange dot
        Positioned(
          top: 240,
          left: 50,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4CAF50),
            ),
          ),
        ),
        // Large blue circle - bottom left
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFB3E5FC).withValues(alpha: 0.3),
            ),
          ),
        ),
        // Large green circle - bottom left, slightly right
        Positioned(
          bottom: -60,
          left: 60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC8E6C9).withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF81D4FA), // Light blue
            Color(0xFF4FC3F7), // Medium blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.string(
          '''
          <svg width="42" height="48" viewBox="0 0 42 48" fill="none" xmlns="http://www.w3.org/2000/svg">
            <g clip-path="url(#clip0_5_90)">
              <path d="M0 7.5C0 5.01562 2.01562 3 4.5 3H13.5C15.9844 3 18 5.01562 18 7.5V16.5C18 18.9844 15.9844 21 13.5 21H4.5C2.01562 21 0 18.9844 0 16.5V7.5ZM6 9V15H12V9H6ZM0 31.5C0 29.0156 2.01562 27 4.5 27H13.5C15.9844 27 18 29.0156 18 31.5V40.5C18 42.9844 15.9844 45 13.5 45H4.5C2.01562 45 0 42.9844 0 40.5V31.5ZM6 33V39H12V33H6ZM28.5 3H37.5C39.9844 3 42 5.01562 42 7.5V16.5C42 18.9844 39.9844 21 37.5 21H28.5C26.0156 21 24 18.9844 24 16.5V7.5C24 5.01562 26.0156 3 28.5 3ZM36 9H30V15H36V9ZM24 28.5C24 27.675 24.675 27 25.5 27H31.5C32.325 27 33 27.675 33 28.5C33 29.325 33.675 30 34.5 30H37.5C38.325 30 39 29.325 39 28.5C39 27.675 39.675 27 40.5 27C41.325 27 42 27.675 42 28.5V37.5C42 38.325 41.325 39 40.5 39H34.5C33.675 39 33 38.325 33 37.5C33 36.675 32.325 36 31.5 36C30.675 36 30 36.675 30 37.5V43.5C30 44.325 29.325 45 28.5 45H25.5C24.675 45 24 44.325 24 43.5V28.5ZM34.5 45C34.1022 45 33.7206 44.842 33.4393 44.5607C33.158 44.2794 33 43.8978 33 43.5C33 43.1022 33.158 42.7206 33.4393 42.4393C33.7206 42.158 34.1022 42 34.5 42C34.8978 42 35.2794 42.158 35.5607 42.4393C35.842 42.7206 36 43.1022 36 43.5C36 43.8978 35.842 44.2794 35.5607 44.5607C35.2794 44.842 34.8978 45 34.5 45ZM40.5 45C40.1022 45 39.7206 44.842 39.4393 44.5607C39.158 44.2794 39 43.8978 39 43.5C39 43.1022 39.158 42.7206 39.4393 42.4393C39.7206 42.158 40.1022 42 40.5 42C40.8978 42 41.2794 42.158 41.5607 42.4393C41.842 42.7206 42 43.1022 42 43.5C42 43.8978 41.842 44.2794 41.5607 44.5607C41.2794 44.842 40.8978 45 40.5 45Z" fill="white"/>
            </g>
            <defs>
              <clipPath id="clip0_5_90">
                <path d="M0 0H42V48H0V0Z" fill="white"/>
              </clipPath>
            </defs>
          </svg>
          ''',
          width: 42,
          height: 48,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLoadingDot(0),
        const SizedBox(width: 8),
        _buildLoadingDot(0.33),
        const SizedBox(width: 8),
        _buildLoadingDot(0.66),
      ],
    );
  }

  Widget _buildLoadingDot(double delay) {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final value = (_loadingController.value + delay) % 1.0;
        final opacity = value < 0.5
            ? 0.3 + (value * 2 * 0.7)
            : 0.3 + ((1 - value) * 2 * 0.7);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4FC3F7).withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}
