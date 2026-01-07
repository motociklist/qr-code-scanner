import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import '../services/apphud_service.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/appsflyer_service.dart';
import '../utils/navigation_helper.dart';
import '../widgets/standard_header.dart';

// Helper to check if platform is mobile (only works on mobile)
bool _isMobile() {
  if (kIsWeb) return false;
  // On web, io will be dart:html which doesn't have Platform
  // On mobile, io will be dart:io which has Platform
  try {
    // ignore: avoid_dynamic_calls
    return (io.Platform as dynamic).isAndroid == true ||
        (io.Platform as dynamic).isIOS == true;
  } catch (e) {
    // On web, Platform doesn't exist, so return false
    return false;
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late MobileScannerController controller;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isPermissionGranted = false;
  bool _isScanning = true;
  String? _scannedCode;
  bool _isTorchOn = false;
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _checkCameraPermission();
    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Load ads
    AdsService.instance.loadInterstitialAd();

    // Log screen view
    AnalyticsService.instance.logScreenView('qr_scanner_screen');
  }

  void _initializeController() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MobileScanner автоматически запускает камеру при отображении
    // При использовании IndexedStack камера должна запуститься автоматически
  }

  Future<void> _checkCameraPermission() async {
    if (kIsWeb) {
      // Web platform - camera access handled differently
      setState(() {
        _isPermissionGranted = true; // Assume granted for web
      });
      return;
    }

    if (_isMobile()) {
      final status = await Permission.camera.request();
      setState(() {
        _isPermissionGranted = status.isGranted;
      });

      if (!_isPermissionGranted) {
        _showPermissionDialog();
      }
    } else {
      // For desktop platforms, assume permission is granted
      setState(() {
        _isPermissionGranted = true;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'Camera permission is required to scan QR codes. '
          'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty && code != _scannedCode) {
        setState(() {
          _scannedCode = code;
          _isScanning = false;
        });

        HapticFeedback.mediumImpact();

        // Check subscription for unlimited scans
        if (!ApphudService.instance.canUseFeature('unlimited_scans')) {
          // Show ad or limit
          AdsService.instance.showInterstitialAd();
          // Log event to AppsFlyer
          AppsFlyerService.instance.logEvent('qr_scan_free');
        } else {
          AppsFlyerService.instance.logEvent('qr_scan_premium');
        }

        _showResultDialog(code);
      }
    }
  }

  void _showResultDialog(String code) async {
    // НЕ сохраняем автоматически в историю - только если пользователь нажмет "Save" или "Share"
    if (mounted) {
      // Используем обычный push вместо replace, чтобы можно было вернуться к экрану сканирования
      await NavigationHelper.push(context, ResultScreen(code: code));
      // После возврата из экрана результата возобновляем сканирование
      if (mounted) {
        setState(() {
          _isScanning = true;
          _scannedCode = null;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // Use image path directly - mobile_scanner handles both File and path strings
        final imagePath = image.path;
        final BarcodeCapture? capture = await controller.analyzeImage(
          imagePath,
        );

        if (capture != null && capture.barcodes.isNotEmpty) {
          final String code = capture.barcodes.first.rawValue ?? '';
          if (code.isNotEmpty) {
            HapticFeedback.mediumImpact();

            // Check subscription
            if (!ApphudService.instance.canUseFeature('unlimited_scans')) {
              AdsService.instance.showInterstitialAd();
              AppsFlyerService.instance.logEvent('qr_scan_from_gallery_free');
            } else {
              AppsFlyerService.instance.logEvent(
                'qr_scan_from_gallery_premium',
              );
            }

            _showResultDialog(code);
          } else {
            _showErrorDialog('No QR code found in the selected image.');
          }
        } else {
          _showErrorDialog('No QR code found in the selected image.');
        }
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleTorch() {
    if (kIsWeb) return; // Torch not supported on web
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    try {
      controller.toggleTorch();
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  void _switchCamera() {
    if (kIsWeb) return; // Camera switching not fully supported on web
    try {
      controller.switchCamera();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with title and info card
              _buildTopSection(),
              // Spacing between top section and scanner
              const SizedBox(height: 40),
              // Scanning area
              _buildScanningArea(),
              // Spacing between scanner and bottom controls
              const SizedBox(height: 40),
              // Bottom controls
              _buildBottomControls(),
              // Spacing between bottom controls and nav menu
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        const StandardHeader(
          title: 'Scan QR Code',
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7ACBFF),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/scan-qr-page/i.svg',
                      width: 6,
                      height: 13,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Align QR code within frame',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep your device steady',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildScanningArea() {
    if (!_isPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Camera permission required',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[300]!, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: _handleBarcode,
                  ),
                  // Scanning line animation
                  _buildScanningLine(constraints.maxHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScanningLine(double containerHeight) {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return Positioned(
          top: _scanLineAnimation.value * (containerHeight - 2),
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.0),
                  Colors.blue,
                  Colors.blue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            iconPath: 'assets/images/scan-qr-page/flash.svg',
            label: 'Flash',
            onPressed: _toggleTorch,
            isActive: _isTorchOn,
            iconWidth: 14,
            iconHeight: 18,
          ),
          _buildControlButton(
            iconPath: 'assets/images/scan-qr-page/switch.svg',
            label: 'Switch',
            onPressed: _switchCamera,
            iconWidth: 18,
            iconHeight: 16,
          ),
          _buildControlButton(
            iconPath: 'assets/images/scan-qr-page/gallery.svg',
            label: 'Gallery',
            onPressed: _pickImageFromGallery,
            iconWidth: 18,
            iconHeight: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    double? iconWidth,
    double? iconHeight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF6F7FA),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: iconWidth ?? 24,
                height: iconHeight ?? 24,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF7ACBFF) : const Color(0xFF5A5A5A),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
