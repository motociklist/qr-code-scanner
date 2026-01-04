import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_qr_code.dart';
import '../services/saved_qr_service.dart';
import '../components/filter_chips.dart';
import '../components/empty_state.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
import '../utils/navigation_helper.dart';
import '../utils/dialog_helper.dart';
import 'result_screen.dart';

class MyQRCodesScreen extends StatefulWidget {
  const MyQRCodesScreen({super.key});

  @override
  State<MyQRCodesScreen> createState() => _MyQRCodesScreenState();
}

class _MyQRCodesScreenState extends State<MyQRCodesScreen> {
  final SavedQRService _savedQRService = SavedQRService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _filters = ['All', 'URL', 'Text', 'WiFi', 'Contact'];

  @override
  void initState() {
    super.initState();
    _loadSavedCodes();
    // Слушаем изменения для автоматической синхронизации
    _savedQRService.addListener(_onSavedCodesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем список при возврате на экран
    _loadSavedCodes();
  }

  @override
  void dispose() {
    _savedQRService.removeListener(_onSavedCodesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSavedCodesChanged() {
    if (mounted) {
      setState(() {}); // Автоматически обновляем UI при изменениях
    }
  }

  Future<void> _loadSavedCodes() async {
    await _savedQRService.loadSavedCodes();
    if (mounted) {
      setState(() {});
    }
  }

  List<SavedQRCode> get _filteredCodes {
    var codes = _savedQRService
        .getCodesByType(_selectedFilter == 'All' ? null : _selectedFilter);
    if (_searchQuery.isNotEmpty) {
      codes = codes.where((code) {
        return code.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            code.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    return codes;
  }

  String _getSubtitle(SavedQRCode code) {
    if (code.type == 'URL') {
      return UrlHelper.getShortUrl(code.content);
    } else if (code.type == 'Contact') {
      return '${code.title} vCard';
    } else {
      return UrlHelper.truncateText(code.content, maxLength: 20);
    }
  }

  void _showOptionsMenu(BuildContext context, SavedQRCode code) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                NavigationHelper.push(
                  context,
                  ResultScreen(code: code.content, fromHistory: true),
                );
                _savedQRService.incrementViewCount(code.id);
                // setState не нужен - автоматически обновится через listener
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('View QR Code'),
              onTap: () {
                Navigator.pop(context);
                _showFullSizeQR(code);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Image'),
              onTap: () {
                Navigator.pop(context);
                _exportQRCode(code);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteCode(code);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCode(SavedQRCode code) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context: context,
      title: 'Delete QR Code',
      content: 'Are you sure you want to delete "${code.title}"?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      await _savedQRService.deleteCode(code.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My QR Codes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            // Search bar (if searching)
            if (_isSearching)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search QR codes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            // Filter tabs
            FilterChips(
              filters: _filters,
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 20),
            // QR Codes grid
            Expanded(
              child: _filteredCodes.isEmpty
                  ? EmptyState(
                      icon: Icons.qr_code_2_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'No QR codes found'
                          : 'No QR codes yet',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Try a different search'
                          : 'Create your first QR code',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredCodes.length,
                      itemBuilder: (context, index) {
                        final code = _filteredCodes[index];
                        return _buildQRCodeCard(code);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeCard(SavedQRCode code) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top blue section with QR icon
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: QrImageView(
                  data: code.content,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.blue[100]!,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),
          // Bottom section with details
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          code.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showOptionsMenu(context, code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(code),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDate(code.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${code.viewCount}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullSizeQR(SavedQRCode code) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: code.content,
                version: QrVersions.auto,
                size: 300,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _exportQRCode(code);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Save'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Share.share(code.content);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportQRCode(SavedQRCode code) async {
    try {
      // Create QR code image using QrPainter
      final painter = QrPainter(
        data: code.content,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      const size = 512.0;
      // Рисуем белый фон
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), backgroundPaint);
      // Рисуем QR код
      painter.paint(canvas, const Size(size, size));
      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory and share
      final directory = await getTemporaryDirectory();
      final fileName = 'qr_code_${code.id}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: code.content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code ready to share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting QR code: $e')),
        );
      }
    }
  }
}
