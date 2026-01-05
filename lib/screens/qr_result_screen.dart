import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import '../models/saved_qr_code.dart';
import '../services/saved_qr_service.dart';
import '../services/analytics_service.dart';
import '../services/history_service.dart';
import '../models/scan_history_item.dart';
import '../constants/app_styles.dart';
import '../utils/navigation_helper.dart';
import 'home_screen.dart';
import 'create_qr_screen.dart';

class QRResultScreen extends StatefulWidget {
  final String qrData;
  final Color qrColor;
  final String qrType;
  final String qrTitle;

  const QRResultScreen({
    super.key,
    required this.qrData,
    required this.qrColor,
    required this.qrType,
    required this.qrTitle,
  });

  @override
  State<QRResultScreen> createState() => _QRResultScreenState();
}

class _QRResultScreenState extends State<QRResultScreen> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('qr_result_screen');
  }

  Future<void> _saveQRCode() async {
    final qrCode = SavedQRCode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: widget.qrTitle,
      content: widget.qrData,
      type: widget.qrType,
      createdAt: DateTime.now(),
    );

    await SavedQRService.instance.saveCode(qrCode);

    // Также сохраняем в историю сканирований с action='Created'
    final historyService = HistoryService();
    await historyService.loadHistory();
    final historyItem = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: widget.qrData,
      timestamp: DateTime.now(),
      type: widget.qrType,
      action: 'Created',
    );
    await historyService.addScan(historyItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code saved successfully')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _shareQR() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        await Share.share(widget.qrData);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        await Share.share(widget.qrData);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([XFile(file.path)], text: widget.qrData);
    } catch (e) {
      await Share.share(widget.qrData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Content - на светлом фоне без белой карточки
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon
                    const SizedBox(height: 20),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), // Green
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    // Status Message
                    const SizedBox(height: 16),
                    const Text(
                      'The QR code is ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    // QR Code Display Area
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7ACBFF), // Light blue
                          width: 1,
                        ),
                      ),
                      child: RepaintBoundary(
                        key: _qrKey,
                        child: QrImageView(
                          data: widget.qrData,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: widget.qrColor,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: widget.qrColor,
                          ),
                        ),
                      ),
                    ),
                    // Action Buttons
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Share Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.share,
                            label: 'Share',
                            onPressed: _shareQR,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Save Button
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.bookmark,
                            label: 'Save',
                            onPressed: _saveQRCode,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.black87,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green[400],
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationHelper.push(context, const CreateQRScreen()),
          borderRadius: BorderRadius.circular(28),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return ClipPath(
      clipper: _BottomNavBarClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem('assets/images/nav_menu/home.svg', 'Home', 0),
                _buildNavItem('assets/images/nav_menu/scan.svg', 'Scan QR', 1),
                const SizedBox(width: 60), // Space for FAB
                _buildNavItem(
                    'assets/images/nav_menu/my_qr_code.svg', 'My QR Codes', 2),
                _buildNavItem(
                    'assets/images/nav_menu/history.svg', 'History', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    const inactiveColor = Color(0xFFB0B0B0); // Grey color

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _navigateToScreen(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  placeholderBuilder: (context) => Container(
                    width: 24,
                    height: 24,
                    color: Colors.transparent,
                  ),
                  semanticsLabel: label,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.tabBarLabel.copyWith(
                color: inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    // Закрываем QRResultScreen и сразу переходим на HomeScreen с нужным табом
    // Заменяем весь стек навигации на HomeScreen с нужным табом
    // Это гарантирует, что навбар и FAB (зеленый кружок с плюсом) будут видны
    Navigator.of(context).pop();
    NavigationHelper.pushAndRemoveUntil(
      context,
      HomeScreen(initialTabIndex: index),
    );
  }
}

// Custom clipper для создания выемки в навигационной панели
class _BottomNavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const notchWidth = 80.0; // Длина выемки
    const notchDepth = 25.0; // Глубина выемки
    final centerX = size.width / 2;

    // Начинаем с левого верхнего угла
    path.moveTo(0, 0);

    // Верхняя линия до начала выемки слева
    const transitionWidth = 15.0; // Ширина переходной зоны
    path.lineTo(centerX - notchWidth / 2 - transitionWidth, 0);

    // Левая часть выемки (симметричная плавная кривая вниз)
    path.cubicTo(
      centerX - notchWidth / 2 - transitionWidth * 0.5,
      0,
      centerX - notchWidth / 2 - transitionWidth * 0.2,
      notchDepth * 1,
      centerX - notchWidth / 2,
      notchDepth,
    );

    // Нижняя часть выемки (симметричный полукруг до максимальной глубины)
    path.arcToPoint(
      Offset(centerX + notchWidth / 2, notchDepth),
      radius: const Radius.elliptical(notchWidth / 2, notchDepth),
      clockwise: false,
    );

    // Правая часть выемки (симметричная плавная кривая вверх)
    path.cubicTo(
      centerX + notchWidth / 2 + transitionWidth * 0.2,
      notchDepth * 1,
      centerX + notchWidth / 2 + transitionWidth * 0.5,
      0,
      centerX + notchWidth / 2 + transitionWidth,
      0,
    );

    // Верхняя линия до правого края
    path.lineTo(size.width, 0);

    // Правый край
    path.lineTo(size.width, size.height);

    // Нижняя линия
    path.lineTo(0, size.height);

    // Закрываем путь
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
