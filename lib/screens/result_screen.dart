import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_history_item.dart';
import '../services/history_service.dart';

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
  bool _isUrl = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isUrl = widget.code.startsWith('http://') || widget.code.startsWith('https://');
    _checkIfSaved();

    if (!widget.fromHistory) {
      _saveToHistory();
    }
  }

  void _checkIfSaved() {
    // Check if this code is already saved
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
      type: _isUrl ? 'URL' : 'TEXT',
    );
    _historyService.addScan(item);
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
                        color: Colors.green[400],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Scan Successful',
                      style: TextStyle(
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
                          // Website URL section
                          if (_isUrl) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.link,
                                  color: Colors.blue[400],
                                  size: 20,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 20),
                          ],
                          // Full Content section
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
                                    _isUrl ? 'URL' : 'TEXT',
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
                    // Open Link button (only for URLs)
                    if (_isUrl)
                      SizedBox(
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
                      ),
                    if (_isUrl) const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
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
