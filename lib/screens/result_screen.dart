import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/scan_history_item.dart';
import '../services/history_service.dart';
import '../services/analytics_service.dart';
import '../services/ads_service.dart';
import '../utils/qr_parser.dart';

class ResultScreen extends StatefulWidget {
  final String code;
  final bool fromHistory;

  const ResultScreen({
    super.key,
    required this.code,
    this.fromHistory = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final HistoryService _historyService = HistoryService();
  QRType _qrType = QRType.text;
  Map<String, String> _parsedData = {};
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _parseQRCode();
    _checkIfSaved();

    if (!widget.fromHistory) {
      _saveToHistory();
      AnalyticsService.instance.logQRScan(_qrType.name);
    }

    AnalyticsService.instance.logScreenView('result_screen');
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

  void _checkIfSaved() {
    final savedCodes = _historyService.history.where((item) => item.code == widget.code).toList();
    setState(() {
      _isSaved = savedCodes.isNotEmpty;
    });
  }

  void _saveToHistory() {
    final item = ScanHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: widget.code,
      timestamp: DateTime.now(),
      type: _getTypeString(),
    );
    _historyService.addScan(item);
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
  }

  void _saveCode() {
    if (!_isSaved) {
      _saveToHistory();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Already saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
        mailto += subject.isNotEmpty ? '&body=${Uri.encodeComponent(body)}' : 'body=${Uri.encodeComponent(body)}';
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
        givenName: _parsedData['name'] ?? '',
        phones: _parsedData['phone'] != null
            ? [Item(label: 'mobile', value: _parsedData['phone']!)]
            : [],
        emails: _parsedData['email'] != null
            ? [Item(label: 'work', value: _parsedData['email']!)]
            : [],
      );

      if (_parsedData['organization'] != null) {
        contact.company = _parsedData['organization'];
      }

      await ContactsService.addContact(contact);

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
          content: Text('WiFi: ${_parsedData['S'] ?? 'Unknown'}\nPassword: ${_parsedData['P'] ?? 'None'}'),
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

  IconData _getTypeIcon() {
    switch (_qrType) {
      case QRType.url:
        return Icons.link;
      case QRType.phone:
        return Icons.phone;
      case QRType.email:
        return Icons.email;
      case QRType.contact:
        return Icons.contact_page;
      case QRType.wifi:
        return Icons.wifi;
      case QRType.sms:
        return Icons.sms;
      default:
        return Icons.text_fields;
    }
  }

  Color _getTypeColor() {
    switch (_qrType) {
      case QRType.url:
        return Colors.blue;
      case QRType.phone:
        return Colors.green;
      case QRType.email:
        return Colors.orange;
      case QRType.contact:
        return Colors.purple;
      case QRType.wifi:
        return Colors.cyan;
      case QRType.sms:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getTypeTitle() {
    switch (_qrType) {
      case QRType.url:
        return 'Website URL';
      case QRType.phone:
        return 'Phone Number';
      case QRType.email:
        return 'Email Address';
      case QRType.contact:
        return 'Contact Information';
      case QRType.wifi:
        return 'WiFi Network';
      case QRType.sms:
        return 'SMS Message';
      default:
        return 'Text Content';
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
                    onPressed: () => Navigator.pop(context),
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
                    // Success indicator
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getTypeColor(),
                      ),
                      child: Icon(
                        _getTypeIcon(),
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getTypeTitle(),
                      style: const TextStyle(
                        fontSize: 22,
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
                                  const Text(
                                    'Just now',
                                    style: TextStyle(
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
                    // Action buttons based on type
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                    // Bottom action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.copy,
                          label: 'Copy',
                          onPressed: _copyToClipboard,
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          onPressed: _shareContent,
                        ),
                        _buildActionButton(
                          icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
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
                Icon(Icons.link, color: Colors.blue[400], size: 20),
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
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
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openUrl,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              'Open Link',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
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
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: isActive ? Colors.blue[400] : Colors.grey[700],
            size: 20,
          ),
          label: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.blue[400] : Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: isActive ? Colors.blue[400]! : Colors.grey[300]!,
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
