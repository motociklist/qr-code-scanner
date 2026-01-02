import 'package:flutter/material.dart';
import '../models/saved_qr_code.dart';
import '../services/saved_qr_service.dart';
import '../components/filter_chips.dart';
import '../components/empty_state.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
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
  }

  Future<void> _loadSavedCodes() async {
    await _savedQRService.loadSavedCodes();
    setState(() {});
  }

  List<SavedQRCode> get _filteredCodes {
    var codes = _savedQRService.getCodesByType(_selectedFilter == 'All' ? null : _selectedFilter);
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
              title: const Text('View'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(code: code.content, fromHistory: true),
                  ),
                );
                _savedQRService.incrementViewCount(code.id);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete QR Code'),
        content: Text('Are you sure you want to delete "${code.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                child: Icon(
                  Icons.qr_code_2,
                  size: 60,
                  color: Colors.blue[700],
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
}
