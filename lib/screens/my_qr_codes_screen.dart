import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/saved_qr_code.dart';
import '../services/saved_qr_service.dart';
import '../components/filter_chips.dart';
import '../components/empty_state.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
import '../utils/dialog_helper.dart';
import '../constants/app_styles.dart';
import '../utils/navigation_helper.dart';
import '../widgets/standard_header.dart';
import 'create_qr_screen.dart';

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
  OverlayEntry? _menuOverlayEntry;

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

  void _showOptionsMenu(
      BuildContext context, SavedQRCode code, Offset tapPosition) {
    _removeOptionsMenu();

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final offset = overlayBox.globalToLocal(tapPosition);

    const menuWidth = 167.0;
    const menuHeight = 88.0;
    const verticalGap = 16.0;

    final left = (offset.dx - menuWidth / 2)
        .clamp(12.0, overlayBox.size.width - menuWidth - 12.0);
    final top = (offset.dy - menuHeight - verticalGap)
        .clamp(12.0, overlayBox.size.height - menuHeight - 12.0);

    _menuOverlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOptionsMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            height: menuHeight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMenuButton(
                      context: context,
                      iconPath: 'assets/images/my_qr_code-page/menu/shared.svg',
                      backgroundColor: const Color(0xFF77C97E),
                      iconSize: const Size(11.3, 10),
                      label: 'Share All',
                      onTap: () {
                        _removeOptionsMenu();
                        _exportQRCode(code);
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      iconPath: 'assets/images/my_qr_code-page/menu/edit.svg',
                      backgroundColor: const Color(0xFF7ACBFF),
                      iconSize: const Size(12, 12),
                      label: 'Edit',
                      onTap: () {
                        _removeOptionsMenu();
                        NavigationHelper.push(
                          context,
                          CreateQRScreen(editingCode: code),
                        );
                      },
                    ),
                    _buildMenuButton(
                      context: context,
                      iconPath: 'assets/images/my_qr_code-page/menu/delete.svg',
                      backgroundColor: const Color(0xFFFFB86C),
                      iconSize: const Size(10, 12),
                      label: 'Delete',
                      onTap: () {
                        _removeOptionsMenu();
                        _deleteCode(code);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_menuOverlayEntry!);
  }

  void _removeOptionsMenu() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String iconPath,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
    required Size iconSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: iconSize.width,
                height: iconSize.height,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppStyles.caption.copyWith(fontSize: 11),
          ),
        ],
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
            // White background container for header and filters
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  StandardHeader(
                    title: 'My QR Codes',
                    trailing: StandardHeader.createIconButton(
                      iconPath: 'assets/images/my_qr_code-page/search.svg',
                      iconWidth: 12,
                      iconHeight: 12,
                    ),
                    onTrailingTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchQuery = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  // Search bar (if searching)
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
          // Top section with blue block containing QR icon
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.topRight,
                    colors: [
                      Color(0xFF7ACBFF), // Светло-голубой
                      Color(0xFF4DA6FF), // Более темный голубой
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/my_qr_code-page/qr.svg',
                    width: 42,
                    height: 42,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom section with details
          Expanded(
            flex: 2,
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
                          style: AppStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (details) => _showOptionsMenu(
                            context, code, details.globalPosition),
                        onTap: () {},
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/my_qr_code-page/dots.svg',
                              width: 11,
                              height: 3,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF5A5A5A),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSubtitle(code),
                    style: AppStyles.smallTextGray,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.formatDate(code.createdAt),
                        style: AppStyles.cardDate,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/my_qr_code-page/eye.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFB0B0B0),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${code.viewCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB0B0B0),
                            ),
                          ),
                        ],
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
