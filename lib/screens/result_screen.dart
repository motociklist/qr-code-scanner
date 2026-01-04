import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/scan_history_item.dart';
import '../services/history_service.dart';
import '../services/analytics_service.dart';
import '../services/ads_service.dart';
import '../utils/qr_parser.dart';
import '../utils/date_formatter.dart';

class ResultScreen extends StatefulWidget {
  final String code;
  final bool fromHistory;
  final String? historyId; // ID записи в истории, если открыто из истории

  const ResultScreen({
    super.key,
    required this.code,
    this.fromHistory = false,
    this.historyId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final HistoryService _historyService = HistoryService();
  QRType _qrType = QRType.text;
  Map<String, String> _parsedData = {};
  bool _isSaved = false;
  String? _savedHistoryId; // ID сохраненной записи в истории

  @override
  void initState() {
    super.initState();
    _parseQRCode();
    loadHistory();
    // Слушаем изменения истории для синхронизации
    _historyService.addListener(_onHistoryChanged);

    // Проверяем сохраненность при инициализации
    _checkIfSaved();

    if (!widget.fromHistory) {
      AnalyticsService.instance.logQRScan(_qrType.name);
    }

    AnalyticsService.instance.logScreenView('result_screen');
  }

  @override
  void dispose() {
    _historyService.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    // Не обновляем состояние сохраненности автоматически
    // Пользователь сам управляет через кнопку Save
  }

  void _parseQRCode() {
    _qrType = QRParser.detectType(widget.code);

    switch (_qrType) {
      case QRType.wifi:
        _parsedData = QRParser.parseWiFi(widget.code);
        break;
      case QRType.contact:
        _parsedData = QRParser.parseContact(widget.code);
        break;
      case QRType.email:
        _parsedData = QRParser.parseEmail(widget.code);
        break;
      case QRType.phone:
        _parsedData = {'phone': QRParser.parsePhone(widget.code)};
        break;
      default:
        _parsedData = {};
    }
  }

  Future<void> _checkIfSaved() async {
    await loadHistory();
    if (!mounted) return;

    // Если открыто из истории и передан historyId, используем его
    if (widget.fromHistory && widget.historyId != null) {
      final item = _historyService.getScanById(widget.historyId!);
      if (item != null && item.code == widget.code) {
        setState(() {
          _isSaved = true;
          _savedHistoryId = item.id;
        });
        return;
      }
    }

    // Иначе ищем по коду (берем первую найденную запись)
    ScanHistoryItem? savedItem;
    try {
      savedItem = _historyService.history
          .where((item) => item.code == widget.code)
          .first;
    } catch (e) {
      savedItem = null;
    }

    if (mounted) {
      setState(() {
        _isSaved = savedItem != null;
        _savedHistoryId = savedItem?.id;
      });
    }
  }

  Future<void> _removeFromHistory() async {
    await loadHistory();
    if (!mounted) return;

    // Удаляем только одну конкретную запись по ID
    if (_savedHistoryId != null) {
      try {
        await _historyService.removeScan(_savedHistoryId!);
      } catch (e) {
        // Error removing from history
      }
    }
  }

  Future<void> _saveToHistory({String action = 'Scanned'}) async {
    await loadHistory();
    final item = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: widget.code,
      timestamp: DateTime.now(),
      type: _getTypeString(),
      action: action,
    );
    await _historyService.addScan(item);
    // Сохраняем ID созданной записи
    _savedHistoryId = item.id;
  }

  String _getTypeString() {
    switch (_qrType) {
      case QRType.url:
        return 'URL';
      case QRType.phone:
        return 'PHONE';
      case QRType.email:
        return 'EMAIL';
      case QRType.contact:
        return 'CONTACT';
      case QRType.wifi:
        return 'WIFI';
      case QRType.sms:
        return 'SMS';
      default:
        return 'TEXT';
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareContent() async {
    await Share.share(widget.code);

    // Всегда создаем новую запись с action 'Shared', даже если код уже сохранен
    await _saveToHistory(action: 'Shared');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved to history'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveCode() async {
    if (!_isSaved) {
      // Сохраняем в историю
      await _saveToHistory();
      setState(() {
        _isSaved = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Удаляем из истории только эту конкретную запись
      await _removeFromHistory();
      setState(() {
        _isSaved = false;
        _savedHistoryId = null; // Очищаем ID после удаления
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from history'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> loadHistory() async {
    await _historyService.loadHistory();
  }

  Future<void> _openUrl() async {
    final uri = Uri.parse(widget.code);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open URL'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _callPhone() async {
    final phone = _parsedData['phone'] ?? '';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail() async {
    final email = _parsedData['email'] ?? '';
    final subject = _parsedData['subject'] ?? '';
    final body = _parsedData['body'] ?? '';

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

    final uri = Uri.parse(mailto);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _addToContacts() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission is required'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final contact = Contact(
        name: Name(first: _parsedData['name'] ?? ''),
      );

      if (_parsedData['phone'] != null) {
        contact.phones = [
          Phone(_parsedData['phone']!, label: PhoneLabel.mobile)
        ];
      }

      if (_parsedData['email'] != null) {
        contact.emails = [Email(_parsedData['email']!, label: EmailLabel.work)];
      }

      if (_parsedData['organization'] != null) {
        contact.organizations = [
          Organization(company: _parsedData['organization']!)
        ];
      }

      await FlutterContacts.insertContact(contact);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _connectToWiFi() async {
    // Note: WiFi connection requires platform-specific implementation
    // This is a placeholder - actual WiFi connection needs native code
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'WiFi: ${_parsedData['S'] ?? 'Unknown'}\nPassword: ${_parsedData['P'] ?? 'None'}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _getShortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      String path = uri.path;
      if (path.length > 20) {
        path = '${path.substring(0, 17)}...';
      }
      return '$host$path';
    } catch (e) {
      if (url.length > 30) {
        return '${url.substring(0, 27)}...';
      }
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with title and close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Scan Result',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      // Если открыто не из истории, возвращаемся на главную страницу
                      if (!widget.fromHistory) {
                        // Закрываем все экраны до главного (HomeScreen)
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      } else {
                        // Если открыто из истории, просто закрываем
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Success indicator - большая зеленая иконка с галочкой
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF77C97E), // Светло-зеленый цвет
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // "Scan Successful"
                    const Text(
                      'Scan Successful',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'QR code decoded successfully',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Main content card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContentSection(),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Scanned and Type info
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scanned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormatter.getTimeAgo(DateTime.now()),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Type',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTypeString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons based on type - кнопка Open Link с градиентом
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    // Bottom action buttons - три кнопки внизу
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          iconPath: 'assets/images/scan_result-page/copy.svg',
                          label: 'Copy',
                          onPressed: _copyToClipboard,
                        ),
                        _buildActionButton(
                          iconPath: 'assets/images/home-page/shared.svg',
                          label: 'Share',
                          onPressed: _shareContent,
                        ),
                        _buildActionButton(
                          iconPath: 'assets/images/scan_result-page/save.svg',
                          label: 'Save',
                          onPressed: _saveCode,
                          isActive: _isSaved,
                        ),
                      ],
                    ),
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
    );
  }

  Widget _buildContentSection() {
    switch (_qrType) {
      case QRType.url:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/scan_result-page/link.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7ACBFF),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Website URL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getShortUrl(widget.code),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Full Content',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.code,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        );
      case QRType.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _parsedData['phone'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        );
      case QRType.email:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.orange[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _parsedData['email'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (_parsedData['subject']?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              const Text(
                'Subject',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _parsedData['subject']!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        );
      case QRType.contact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_page, color: Colors.purple[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_parsedData['name']?.isNotEmpty == true)
              _buildContactField('Name', _parsedData['name']!),
            if (_parsedData['phone']?.isNotEmpty == true)
              _buildContactField('Phone', _parsedData['phone']!),
            if (_parsedData['email']?.isNotEmpty == true)
              _buildContactField('Email', _parsedData['email']!),
            if (_parsedData['organization']?.isNotEmpty == true)
              _buildContactField('Organization', _parsedData['organization']!),
            if (_parsedData['address']?.isNotEmpty == true)
              _buildContactField('Address', _parsedData['address']!),
          ],
        );
      case QRType.wifi:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: Colors.cyan[400], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'WiFi Network',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_parsedData['S']?.isNotEmpty == true)
              _buildContactField('Network Name', _parsedData['S']!),
            if (_parsedData['T']?.isNotEmpty == true)
              _buildContactField('Security', _parsedData['T']!),
            if (_parsedData['P']?.isNotEmpty == true)
              _buildContactField('Password', '••••••••'),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Full Content',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.code,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildContactField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_qrType) {
      case QRType.url:
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7ACBFF),
                Color(0xFF5AB8E8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton.icon(
            onPressed: _openUrl,
            icon: SvgPicture.asset(
              'assets/images/scan_result-page/open_link.svg',
              width: 20,
              height: 20,
            ),
            label: const Text(
              'Open Link',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case QRType.phone:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _callPhone,
            icon: const Icon(Icons.phone, color: Colors.white),
            label: const Text(
              'Call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case QRType.email:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.email, color: Colors.white),
            label: const Text(
              'Send Email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case QRType.contact:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addToContacts,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Add to Contacts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      case QRType.wifi:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connectToWiFi,
            icon: const Icon(Icons.wifi, color: Colors.white),
            label: const Text(
              'Connect to WiFi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required String iconPath,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: isActive ? const Color(0xFF7ACBFF) : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
            backgroundColor: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isActive ? const Color(0xFF7ACBFF) : const Color(0xFF5A5A5A),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFF7ACBFF) : Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
