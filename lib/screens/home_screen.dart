import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'qr_scanner_screen.dart';
import 'history_screen.dart';
import 'my_qr_codes_screen.dart';
import 'create_qr_screen.dart';
import '../services/history_service.dart';
import '../models/scan_history_item.dart';
import 'result_screen.dart';
import '../services/apphud_service.dart';
import 'pricing_screen.dart';
import '../utils/navigation_helper.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
import '../constants/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTabScreen(),
    const QRScannerScreen(),
    const MyQRCodesScreen(),
    const HistoryScreen(),
  ];

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
                  _buildNavItem(
                      'assets/images/nav_menu/history.svg', 'History', 3),
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
    final activeColor = const Color(0xFF7ACBFF); // Light blue from gradient
    final inactiveColor = const Color(0xFFB0B0B0); // Grey color

    // Выбираем активную или неактивную версию иконки
    final String activeIconPath = iconPath.replaceAll('.svg', '-activ.svg');
    final String finalIconPath = isSelected ? activeIconPath : iconPath;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
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
  const HomeTabScreen({super.key});

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
                      icon: Icons.qr_code_scanner,
                      iconColor: Colors.blue[400]!,
                      title: 'Scan QR',
                      subtitle: 'Quick scan',
                      onTap: () => NavigationHelper.push(
                          context, const QRScannerScreen()),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.add_circle,
                      iconColor: Colors.green[400]!,
                      title: 'Create QR',
                      subtitle: 'Generate new',
                      onTap: () {
                        if (!ApphudService.instance
                            .canUseFeature('create_qr')) {
                          NavigationHelper.push(context, const PricingScreen());
                        } else {
                          NavigationHelper.push(
                              context, const CreateQRScreen());
                        }
                      },
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.folder,
                      iconColor: Colors.orange[400]!,
                      title: 'My QR Codes',
                      subtitle: 'Saved codes',
                      onTap: () => NavigationHelper.push(
                          context, const MyQRCodesScreen()),
                    ),
                    _buildActionCard(
                      context,
                      icon: Icons.history,
                      iconColor: Colors.grey[600]!,
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
    required IconData icon,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 26,
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
                  maxLines: 1,
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
    final displayText = UrlHelper.truncateText(item.code, maxLength: 30);

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
            ResultScreen(code: item.code, fromHistory: true),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue[50],
                  ),
                  child: Icon(
                    isUrl ? Icons.link : Icons.qr_code,
                    color: Colors.blue[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUrl ? 'Scanned website link' : displayText,
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
    final notchWidth = 80.0; // Длина выемки
    final notchDepth = 25.0; // Глубина выемки
    final centerX = size.width / 2;

    // Начинаем с левого верхнего угла
    path.moveTo(0, 0);

    // Верхняя линия до начала выемки слева
    final transitionWidth = 15.0; // Ширина переходной зоны
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
      radius: Radius.elliptical(notchWidth / 2, notchDepth),
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
