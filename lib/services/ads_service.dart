import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'apphud_service.dart';

class AdsService {
  static AdsService? _instance;
  AdsService._();

  static AdsService get instance {
    _instance ??= AdsService._();
    return _instance!;
  }

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;

  // Test ad unit IDs - Replace with your actual ad unit IDs
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  // Production ad unit IDs - Replace with your actual ad unit IDs when ready
  // static const String _interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';
  // static const String _rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';
  // static const String _bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';

  bool _isInitialized = false;

  /// Initialize Google Mobile Ads
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Google Mobile Ads doesn't fully support web
    if (kIsWeb) {
      debugPrint('Google Mobile Ads has limited support on web platform');
      _isInitialized = true;
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Google Mobile Ads: $e');
    }
  }

  /// Check if ads should be shown (not for premium users)
  bool shouldShowAds() {
    return !ApphudService.instance.isPremium;
  }

  /// Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (kIsWeb) return; // Ads not fully supported on web
    if (!shouldShowAds()) return;

    await InterstitialAd.load(
      adUnitId: _testInterstitialAdUnitId, // Use test ID for development
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _setInterstitialAdListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (kIsWeb) return; // Ads not fully supported on web
    if (!shouldShowAds()) return;

    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      // Load a new ad for next time
      await loadInterstitialAd();
    }
  }

  /// Set listeners for interstitial ad
  void _setInterstitialAdListeners() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        // Load a new ad
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        // Load a new ad
        loadInterstitialAd();
      },
    );
  }

  /// Load rewarded ad
  Future<void> loadRewardedAd() async {
    if (kIsWeb) return; // Ads not fully supported on web
    if (!shouldShowAds()) return;

    await RewardedAd.load(
      adUnitId: _testRewardedAdUnitId, // Use test ID for development
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _setRewardedAdListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  /// Show rewarded ad
  Future<bool> showRewardedAd() async {
    if (kIsWeb) return false; // Ads not fully supported on web
    if (!shouldShowAds()) return false;

    if (_rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // User earned reward
        },
      );
      _rewardedAd = null;
      return true;
    } else {
      // Load a new ad for next time
      await loadRewardedAd();
      return false;
    }
  }

  /// Set listeners for rewarded ad
  void _setRewardedAdListeners() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        // Load a new ad
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        // Load a new ad
        loadRewardedAd();
      },
    );
  }

  /// Create banner ad widget
  Widget createBannerAd({double height = 50}) {
    if (kIsWeb) {
      return const SizedBox.shrink(); // Ads not fully supported on web
    }

    if (!shouldShowAds()) {
      return const SizedBox.shrink();
    }

    _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: _testBannerAdUnitId, // Use test ID for development
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: height,
      child: AdWidget(ad: _bannerAd!),
    );
  }

  /// Dispose all ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}

