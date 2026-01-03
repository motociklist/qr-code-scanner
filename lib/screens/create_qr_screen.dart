import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import '../models/saved_qr_code.dart';
import '../services/saved_qr_service.dart';
import '../services/apphud_service.dart';
import '../services/analytics_service.dart';
import '../services/ads_service.dart';
import '../services/appsflyer_service.dart';
import '../services/history_service.dart';
import '../models/scan_history_item.dart';
import 'pricing_screen.dart';

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
  final GlobalKey _qrKey = GlobalKey();
  String? _generatedQRData;

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
            mailto += subject.isNotEmpty ? '&body=${Uri.encodeComponent(body)}' : 'body=${Uri.encodeComponent(body)}';
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
    final security = _controllers[QRType.wifi]!['security']!.text.trim().toUpperCase();
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

    // Check subscription for creating QR codes
    if (!ApphudService.instance.canUseFeature('create_qr')) {
      _showSubscriptionRequired();
      AppsFlyerService.instance.logEvent('create_qr_blocked');
      return;
    }

    AppsFlyerService.instance.logEvent('create_qr_success', eventValues: {
      'type': _selectedType.name,
    });

    setState(() {
      _generatedQRData = data;
    });

    AnalyticsService.instance.logQRCreate(_selectedType.name);
  }

  void _showSubscriptionRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Required'),
        content: const Text('Creating QR codes requires a premium subscription.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PricingScreen()),
              );
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQRCode() async {
    if (_generatedQRData == null) return;

    final title = _getTitleForType();
    final type = _getTypeString();

    final qrCode = SavedQRCode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: _generatedQRData!,
      type: type,
      createdAt: DateTime.now(),
    );

    await SavedQRService.instance.saveCode(qrCode);

    // Также сохраняем в историю сканирований с action='Created'
    final historyService = HistoryService();
    await historyService.loadHistory();
    final historyItem = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _generatedQRData!,
      timestamp: DateTime.now(),
      type: type,
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

  Future<void> _saveImage() async {
    if (_generatedQRData == null) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // Save to temporary directory and share
      final directory = await getTemporaryDirectory();
      final fileName = 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share the image file
      await Share.shareXFiles([XFile(file.path)], text: 'QR Code');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code image ready to share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  Future<void> _shareQR() async {
    if (_generatedQRData == null) return;

    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        await Share.share(_generatedQRData!);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        await Share.share(_generatedQRData!);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles([XFile(file.path)], text: _generatedQRData!);
    } catch (e) {
      await Share.share(_generatedQRData!);
    }
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
      appBar: AppBar(
        title: const Text('Create QR Code'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
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
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _generateQR();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                  ),
                  const SizedBox(height: 24),
                  // Generated QR code
                  if (_generatedQRData != null) _buildGeneratedQR(),
                ],
              ),
            ),
          ),
          // Banner ad
          if (AdsService.instance.shouldShowAds())
            AdsService.instance.createBannerAd(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeChip('URL', QRType.url, Icons.link),
            const SizedBox(width: 8),
            _buildTypeChip('Text', QRType.text, Icons.text_fields),
            const SizedBox(width: 8),
            _buildTypeChip('Phone', QRType.phone, Icons.phone),
            const SizedBox(width: 8),
            _buildTypeChip('Email', QRType.email, Icons.email),
            const SizedBox(width: 8),
            _buildTypeChip('Contact', QRType.contact, Icons.contact_page),
            const SizedBox(width: 8),
            _buildTypeChip('WiFi', QRType.wifi, Icons.wifi),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, QRType type, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
          _generatedQRData = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[400] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _getInputFieldsForType(),
      ),
    );
  }

  List<Widget> _getInputFieldsForType() {
    switch (_selectedType) {
      case QRType.url:
        return [
          _buildTextField(
            controller: _controllers[QRType.url]!['url']!,
            label: 'URL',
            hint: 'https://example.com',
            icon: Icons.link,
            keyboardType: TextInputType.url,
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
          _buildTextField(
            controller: _controllers[QRType.contact]!['name']!,
            label: 'Name',
            hint: 'John Doe',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['phone']!,
            label: 'Phone',
            hint: '+1234567890',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['email']!,
            label: 'Email',
            hint: 'example@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['organization']!,
            label: 'Organization (Optional)',
            hint: 'Company name',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.contact]!['address']!,
            label: 'Address (Optional)',
            hint: 'Street address',
            icon: Icons.location_on,
            maxLines: 2,
          ),
        ];
      case QRType.wifi:
        return [
          _buildTextField(
            controller: _controllers[QRType.wifi]!['ssid']!,
            label: 'Network Name (SSID)',
            hint: 'WiFi Network Name',
            icon: Icons.wifi,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _controllers[QRType.wifi]!['password']!,
            label: 'Password',
            hint: 'WiFi Password',
            icon: Icons.lock,
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
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
  }) {
    final initialValue = controller.text.isEmpty ? options.first : controller.text;
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

  Widget _buildGeneratedQR() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          RepaintBoundary(
            key: _qrKey,
            child: QrImageView(
              data: _generatedQRData!,
              version: QrVersions.auto,
              size: 250,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.save,
                label: 'Save',
                onPressed: _saveQRCode,
              ),
              _buildActionButton(
                icon: Icons.image,
                label: 'Save Image',
                onPressed: _saveImage,
              ),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: _shareQR,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[50],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.blue[400]),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
