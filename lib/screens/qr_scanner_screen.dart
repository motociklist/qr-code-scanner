import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';
import '../services/apphud_service.dart';
import '../services/ads_service.dart';
import '../services/analytics_service.dart';
import '../services/appsflyer_service.dart';
import '../services/history_service.dart';
import '../models/scan_history_item.dart';
import '../utils/navigation_helper.dart';

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
    // Save to history
    final historyService = HistoryService();
    await historyService.loadHistory();
    final item = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: code,
      timestamp: DateTime.now(),
      type: _detectQRType(code),
      action: 'Scanned',
    );
    await historyService.addScan(item);

    if (mounted) {
      NavigationHelper.push(context, ResultScreen(code: code), replace: true);
    }
  }

  String? _detectQRType(String code) {
    if (code.startsWith('http://') || code.startsWith('https://')) {
      return 'URL';
    } else if (code.startsWith('tel:')) {
      return 'PHONE';
    } else if (code.startsWith('mailto:')) {
      return 'EMAIL';
    } else if (code.startsWith('WIFI:')) {
      return 'WIFI';
    } else if (code.startsWith('BEGIN:VCARD')) {
      return 'CONTACT';
    } else if (code.startsWith('sms:')) {
      return 'SMS';
    }
    return 'TEXT';
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top section with title and info card
            _buildTopSection(),
            // Scanning area
            Expanded(child: _buildScanningArea()),
            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Scan QR Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[100],
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.flash_on,
            label: 'Flash',
            onPressed: _toggleTorch,
            isActive: _isTorchOn,
          ),
          _buildControlButton(
            icon: Icons.cameraswitch,
            label: 'Switch',
            onPressed: _switchCamera,
          ),
          _buildControlButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onPressed: _pickImageFromGallery,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue[100] : Colors.white,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.blue : Colors.grey[700],
              size: 28,
            ),
            onPressed: onPressed,
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
