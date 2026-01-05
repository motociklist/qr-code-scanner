import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
// FIXME: Temporarily disabled - re-enable when subscription check is restored
// import '../services/apphud_service.dart';
import '../services/analytics_service.dart';
import '../services/ads_service.dart';
import '../services/appsflyer_service.dart';
import '../constants/app_styles.dart';
import 'qr_result_screen.dart';
// FIXME: Temporarily disabled - re-enable when subscription check is restored
// import '../utils/navigation_helper.dart';
// import 'pricing_screen.dart';

enum QRType {
  url,
  text,
  phone,
  email,
  contact,
  wifi,
}

class CreateQRScreen extends StatefulWidget {
  const CreateQRScreen({super.key});

  @override
  State<CreateQRScreen> createState() => _CreateQRScreenState();
}

class _CreateQRScreenState extends State<CreateQRScreen> {
  QRType _selectedType = QRType.url;
  final Map<QRType, Map<String, TextEditingController>> _controllers = {};
  Color _selectedColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    AnalyticsService.instance.logScreenView('create_qr_screen');
  }

  void _initializeControllers() {
    _controllers[QRType.url] = {
      'url': TextEditingController(),
    };
    _controllers[QRType.text] = {
      'text': TextEditingController(),
    };
    _controllers[QRType.phone] = {
      'phone': TextEditingController(),
    };
    _controllers[QRType.email] = {
      'email': TextEditingController(),
      'subject': TextEditingController(),
      'body': TextEditingController(),
    };
    _controllers[QRType.contact] = {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'email': TextEditingController(),
      'organization': TextEditingController(),
      'address': TextEditingController(),
    };
    _controllers[QRType.wifi] = {
      'ssid': TextEditingController(),
      'password': TextEditingController(),
      'security': TextEditingController(text: 'WPA'),
    };
  }

  @override
  void dispose() {
    for (var controllers in _controllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  String _buildQRData() {
    switch (_selectedType) {
      case QRType.url:
        final url = _controllers[QRType.url]!['url']!.text.trim();
        return url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';
      case QRType.text:
        return _controllers[QRType.text]!['text']!.text.trim();
      case QRType.phone:
        return 'tel:${_controllers[QRType.phone]!['phone']!.text.trim()}';
      case QRType.email:
        final email = _controllers[QRType.email]!['email']!.text.trim();
        final subject = _controllers[QRType.email]!['subject']!.text.trim();
        final body = _controllers[QRType.email]!['body']!.text.trim();
        String mailto = 'mailto:$email';
        if (subject.isNotEmpty || body.isNotEmpty) {
          mailto += '?';
          if (subject.isNotEmpty) {
            mailto += 'subject=${Uri.encodeComponent(subject)}';
          }
          if (body.isNotEmpty) {
            mailto += subject.isNotEmpty
                ? '&body=${Uri.encodeComponent(body)}'
                : 'body=${Uri.encodeComponent(body)}';
          }
        }
        return mailto;
      case QRType.contact:
        return _buildVCard();
      case QRType.wifi:
        return _buildWiFiString();
    }
  }

  String _buildVCard() {
    final name = _controllers[QRType.contact]!['name']!.text.trim();
    final phone = _controllers[QRType.contact]!['phone']!.text.trim();
    final email = _controllers[QRType.contact]!['email']!.text.trim();
    final org = _controllers[QRType.contact]!['organization']!.text.trim();
    final address = _controllers[QRType.contact]!['address']!.text.trim();

    final vcard = StringBuffer();
    vcard.writeln('BEGIN:VCARD');
    vcard.writeln('VERSION:3.0');
    if (name.isNotEmpty) vcard.writeln('FN:$name');
    if (name.isNotEmpty) vcard.writeln('N:$name;;;;');
    if (phone.isNotEmpty) vcard.writeln('TEL:$phone');
    if (email.isNotEmpty) vcard.writeln('EMAIL:$email');
    if (org.isNotEmpty) vcard.writeln('ORG:$org');
    if (address.isNotEmpty) vcard.writeln('ADR:;;$address;;;;');
    vcard.writeln('END:VCARD');
    return vcard.toString();
  }

  String _buildWiFiString() {
    final ssid = _controllers[QRType.wifi]!['ssid']!.text.trim();
    final password = _controllers[QRType.wifi]!['password']!.text.trim();
    final security =
        _controllers[QRType.wifi]!['security']!.text.trim().toUpperCase();
    return 'WIFI:T:$security;S:$ssid;P:$password;;';
  }

  void _generateQR() {
    final data = _buildQRData();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // FIXME: Temporarily disabled subscription check for creating QR codes
    // TODO: Re-enable subscription check when ready
    // Check subscription for creating QR codes
    // if (!ApphudService.instance.canUseFeature('create_qr')) {
    //   _showSubscriptionRequired();
    //   AppsFlyerService.instance.logEvent('create_qr_blocked');
    //   return;
    // }

    AppsFlyerService.instance.logEvent('create_qr_success', eventValues: {
      'type': _selectedType.name,
    });

    AnalyticsService.instance.logQRCreate(_selectedType.name);

    // Navigate to QR result screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRResultScreen(
          qrData: data,
          qrColor: _selectedColor,
          qrType: _getTypeString(),
          qrTitle: _getTitleForType(),
        ),
      ),
    );
  }

  // FIXME: Temporarily disabled - re-enable when subscription check is restored
  // ignore: unused_element
  void _showSubscriptionRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Required'),
        content:
            const Text('Creating QR codes requires a premium subscription.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // FIXME: Temporarily disabled - re-enable when subscription check is restored
              // NavigationHelper.push(context, const PricingScreen());
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }


  String _getTitleForType() {
    switch (_selectedType) {
      case QRType.url:
        return _controllers[QRType.url]!['url']!.text.trim();
      case QRType.text:
        return 'Text QR Code';
      case QRType.phone:
        return _controllers[QRType.phone]!['phone']!.text.trim();
      case QRType.email:
        return _controllers[QRType.email]!['email']!.text.trim();
      case QRType.contact:
        return _controllers[QRType.contact]!['name']!.text.trim().isEmpty
            ? 'Contact QR Code'
            : _controllers[QRType.contact]!['name']!.text.trim();
      case QRType.wifi:
        return _controllers[QRType.wifi]!['ssid']!.text.trim();
    }
  }

  String _getTypeString() {
    switch (_selectedType) {
      case QRType.url:
        return 'URL';
      case QRType.text:
        return 'Text';
      case QRType.phone:
        return 'Phone';
      case QRType.email:
        return 'Email';
      case QRType.contact:
        return 'Contact';
      case QRType.wifi:
        return 'WiFi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR Type selector
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    // Input fields
                    _buildInputFields(),
                    const SizedBox(height: 24),
                    // Design Options
                    _buildDesignOptions(),
                    const SizedBox(height: 24),
                    // Generate button
                    _buildGenerateButton(),
                  ],
                ),
              ),
            ),
            // Banner ad
            if (AdsService.instance.shouldShowAds())
              AdsService.instance.createBannerAd(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              'Create QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/creacte-page/cross.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: URL, Text, Contact
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                  'URL', QRType.url, 'assets/images/creacte-page/link.svg'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                  'Text', QRType.text, 'assets/images/creacte-page/a.svg'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard('Contact', QRType.contact,
                  'assets/images/creacte-page/person.svg'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Wi-Fi
        _buildTypeCard(
            'Wi-Fi', QRType.wifi, 'assets/images/creacte-page/wi-fi.svg'),
      ],
    );
  }

  Widget _buildTypeCard(String label, QRType type, String iconPath) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF5A5A5A) : const Color(0xFF5A5A5A),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF5A5A5A),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _getInputFieldsForType(),
    );
  }

  List<Widget> _getInputFieldsForType() {
    switch (_selectedType) {
      case QRType.url:
        return [
          const Text(
            'Website URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _controllers[QRType.url]!['url']!,
            label: null,
            hint: 'https://example.com',
            icon: null,
            keyboardType: TextInputType.url,
            showIconOnRight: true,
          ),
        ];
      case QRType.text:
        return [
          _buildTextField(
            controller: _controllers[QRType.text]!['text']!,
            label: 'Text',
            hint: 'Enter your text',
            icon: Icons.text_fields,
            maxLines: 5,
          ),
        ];
      case QRType.phone:
        return [
          _buildTextField(
            controller: _controllers[QRType.phone]!['phone']!,
            label: 'Phone Number',
            hint: '+1234567890',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ];
      case QRType.email:
        return [
          _buildTextField(
            controller: _controllers[QRType.email]!['email']!,
            label: 'Email',
            hint: 'example@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.email]!['subject']!,
            label: 'Subject (Optional)',
            hint: 'Email subject',
            icon: Icons.subject,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.email]!['body']!,
            label: 'Body (Optional)',
            hint: 'Email body',
            icon: Icons.message,
            maxLines: 3,
          ),
        ];
      case QRType.contact:
        return [
          const Text(
            'Contact',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _controllers[QRType.contact]!['name']!,
            label: null,
            hint: 'Name',
            icon: null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['phone']!,
            label: null,
            hint: 'Phone',
            icon: null,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['email']!,
            label: null,
            hint: 'Email',
            icon: null,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['organization']!,
            label: null,
            hint: 'Organization (Optional)',
            icon: null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['address']!,
            label: null,
            hint: 'Address (Optional)',
            icon: null,
            maxLines: 2,
          ),
        ];
      case QRType.wifi:
        return [
          const Text(
            'Wi-Fi Network',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _controllers[QRType.wifi]!['ssid']!,
            label: null,
            hint: 'Network Name (SSID)',
            icon: null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.wifi]!['password']!,
            label: null,
            hint: 'Password',
            icon: null,
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            controller: _controllers[QRType.wifi]!['security']!,
            label: 'Security Type',
            icon: Icons.security,
            options: ['WPA', 'WEP', 'nopass'],
          ),
        ];
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    bool showIconOnRight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null && !showIconOnRight
              ? Icon(icon, color: Colors.grey[600])
              : null,
          suffixIcon: showIconOnRight
              ? IconButton(
                  icon: SvgPicture.asset(
                    'assets/images/creacte-page/link.svg',
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () async {
                    final clipboardData =
                        await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData?.text != null) {
                      controller.text = clipboardData!.text!;
                    }
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDesignOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Design Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color section
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildColorSwatch(Colors.black),
                  const SizedBox(width: 12),
                  _buildColorSwatch(const Color(0xFF7ACBFF)), // Light blue
                  const SizedBox(width: 12),
                  _buildColorSwatch(const Color(0xFF4CAF50)), // Light green
                  const SizedBox(width: 12),
                  _buildColorSwatch(const Color(0xFFFF9800)), // Orange
                ],
              ),
              const SizedBox(height: 20),
              // Add Logo section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '+ Add Logo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Pro Feature',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7ACBFF), // Light blue
            Color(0xFF4DA6FF), // Darker blue
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _generateQR,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Generate QR Code',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
  }) {
    final initialValue =
        controller.text.isEmpty ? options.first : controller.text;
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        controller.text = value ?? options.first;
      },
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
          // Просто закрываем CreateQRScreen, пользователь вернется на HomeScreen
          Navigator.pop(context);
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
