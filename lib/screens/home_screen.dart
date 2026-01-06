import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'qr_scanner_screen.dart';
import 'history_screen.dart';
import 'my_qr_codes_screen.dart';
import 'create_qr_screen.dart';
import '../services/history_service.dart';
import '../models/scan_history_item.dart';
import 'result_screen.dart';
import '../utils/navigation_helper.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
import '../constants/app_styles.dart';
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex ?? 0;
    _screens = [
      HomeTabScreen(onNavigateToScan: () {
        setState(() {
          _currentIndex = 1;
        });
      }),
      const QRScannerScreen(),
      const MyQRCodesScreen(),
      const HistoryScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipPath(
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
                  _buildNavItem(
                      'assets/images/nav_menu/scan.svg', 'Scan QR', 1),
                  const SizedBox(width: 60), // Space for FAB
                  _buildNavItem('assets/images/nav_menu/my_qr_code.svg',
                      'My QR Codes', 2),
                  // History uses PNG icon
                  _buildNavItem(
                      'assets/images/nav_menu/history-png.png', 'History', 3),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF7ACBFF); // Light blue from gradient
    const inactiveColor = Color(0xFFB0B0B0); // Grey color

    final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
    final bool isPng = iconPath.toLowerCase().endsWith('.png');

    // Выбираем активную или неактивную версию иконки
    String finalIconPath = iconPath;
    if (isSelected) {
      if (isSvg) {
        finalIconPath = iconPath.replaceFirst('.svg', '-activ.svg');
      } else if (isPng) {
        // Пробуем найти активную PNG версию
        final String activePngPath =
            iconPath.replaceFirst('.png', '-activ.png');
        // Если активной PNG нет, используем SVG активную версию (для истории)
        if (iconPath.contains('history')) {
          finalIconPath =
              iconPath.replaceFirst('history-png.png', 'history-activ.svg');
        } else {
          finalIconPath = activePngPath;
        }
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          // Если переключаемся на экран сканирования, убеждаемся что камера запущена
          if (index == 1) {
            // Даем время для переключения экрана
            Future.delayed(const Duration(milliseconds: 100), () {
              // Экран сканирования сам запустит камеру в didChangeDependencies
            });
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (finalIconPath.toLowerCase().endsWith('.svg'))
                  SvgPicture.asset(
                    finalIconPath,
                    width: 24,
                    height: 24,
                    placeholderBuilder: (context) => Container(
                      width: 24,
                      height: 24,
                      color: Colors.transparent,
                    ),
                    semanticsLabel: label,
                  )
                else
                  Image.asset(
                    finalIconPath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppStyles.tabBarLabel.copyWith(
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTabScreen extends StatefulWidget {
  final VoidCallback? onNavigateToScan;

  const HomeTabScreen({super.key, this.onNavigateToScan});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Слушаем изменения истории
    _historyService.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    _historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadHistory() async {
    await _historyService.loadHistory();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем историю при появлении экрана
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final recentHistory = _historyService.history.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Welcome section
                const Text(
                  'Welcome, Name!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your QR codes easily',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                // Action Cards Grid (2x2)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildActionCard(
                      context,
                      iconPath: 'assets/images/nav_menu/scan-activ.svg',
                      iconColor: const Color(0xFF7ACBFF), // Bright blue
                      title: 'Scan QR',
                      subtitle: 'Quick scan',
                      onTap: () {
                        widget.onNavigateToScan?.call();
                      },
                    ),
                    _buildActionCard(
                      context,
                      iconPath: 'assets/images/nav_menu/plus.svg',
                      iconColor: const Color(0xFF77C97E), // Bright green
                      title: 'Create QR',
                      subtitle: 'Generate new',
                      onTap: () {
                        NavigationHelper.push(context, const CreateQRScreen());
                      },
                    ),
                    _buildActionCard(
                      context,
                      iconPath: 'assets/images/nav_menu/my_qr_code-activ.svg',
                      iconColor: const Color(0xFFFFB86C), // Bright orange
                      title: 'My QR Codes',
                      subtitle: 'Saved codes',
                      onTap: () => NavigationHelper.push(
                          context, const MyQRCodesScreen()),
                    ),
                    _buildActionCard(
                      context,
                      iconPath: 'assets/images/nav_menu/history-activ.svg',
                      iconColor: const Color(0xFFB0B0B0), // Grey
                      title: 'History',
                      subtitle: 'Recent scans',
                      onTap: () =>
                          NavigationHelper.push(context, const HistoryScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Recent Activity section
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                if (recentHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...recentHistory
                      .map((item) => _buildRecentActivityItem(context, item)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String iconPath,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 25,
                      height: 25,
                      colorFilter: ColorFilter.mode(
                        AppTheme.colors.strokeColor,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (context) => Container(
                        width: 25,
                        height: 25,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(BuildContext context, ScanHistoryItem item) {
    final isUrl = UrlHelper.isUrl(item.code);
    final isCreated = item.action == 'Created';
    final isShared = item.action == 'Shared';
    final isWifi = item.type == 'WIFI';
    final isContact = item.type == 'CONTACT';

    // Определяем иконку и цвет в зависимости от типа активности
    String iconPath;
    Color iconColor;
    String activityText;

    if (isCreated && isWifi) {
      iconPath = 'assets/images/home-page/plus.svg';
      iconColor = const Color(0xFF77C97E); // Bright green
      activityText = 'Created WiFi QR';
    } else if ((isCreated || isShared) && isContact) {
      iconPath = 'assets/images/home-page/shared.svg';
      iconColor = const Color(0xFFFFB86C); // Bright orange
      activityText = 'Shared contact QR';
    } else if (isShared) {
      iconPath = 'assets/images/home-page/shared.svg';
      iconColor = const Color(0xFFFFB86C); // Bright orange
      activityText = 'Shared QR code';
    } else if (isUrl) {
      iconPath = 'assets/images/home-page/link.svg';
      iconColor = const Color(0xFF7ACBFF); // Bright blue
      activityText = 'Scanned website link';
    } else {
      iconPath = 'assets/images/home-page/link.svg';
      iconColor = const Color(0xFF7ACBFF); // Bright blue
      activityText = 'Scanned QR code';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationHelper.push(
            context,
            ResultScreen(
              code: item.code,
              fromHistory: true,
              historyId: item.id,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconPath,
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(
                        AppTheme.colors.strokeColor,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (context) => Container(
                        width: 12,
                        height: 12,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activityText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.getTimeAgo(item.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
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
