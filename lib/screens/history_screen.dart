import 'package:flutter/material.dart';
import '../models/scan_history_item.dart';
import '../services/history_service.dart';
import '../components/filter_chips.dart';
import '../components/action_buttons.dart';
import '../components/icon_circle.dart';
import '../components/empty_state.dart';
import '../utils/date_formatter.dart';
import '../utils/url_helper.dart';
import '../utils/qr_type_helper.dart';
import '../utils/navigation_helper.dart';
import '../utils/dialog_helper.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Слушаем изменения истории для автоматической синхронизации
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

  List<ScanHistoryItem> get _filteredHistory {
    var history = _historyService.history;
    if (_selectedFilter == 'Scanned') {
      history = history.where((item) => item.action == 'Scanned').toList();
    } else if (_selectedFilter == 'Created') {
      history = history.where((item) => item.action == 'Created').toList();
    }
    return history;
  }

  Map<String, List<ScanHistoryItem>> get _groupedHistory {
    final Map<String, List<ScanHistoryItem>> grouped = {};

    for (final item in _filteredHistory) {
      final groupKey = DateFormatter.getGroupKey(item.timestamp);
      grouped.putIfAbsent(groupKey, () => []).add(item);
    }

    return grouped;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем историю при появлении экрана
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupedHistory;
    final sortedKeys = groupedHistory.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        return b.compareTo(a);
      });

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
                    'History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[700],
                    ),
                    onSelected: (value) {
                      if (value == 'clear') {
                        _clearAllHistory();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Clear All History', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Filter tabs
            FilterChips(
              filters: const ['All', 'Scanned', 'Created'],
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
            const SizedBox(height: 20),
            // History list
            Expanded(
              child: groupedHistory.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'No history yet',
                      subtitle: 'Scanned QR codes will\nappear here',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        final groupKey = sortedKeys[index];
                        final items = groupedHistory[groupKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
                              child: Text(
                                groupKey,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ...items.map((item) => _buildHistoryItem(item)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ScanHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              // Icon
              IconCircle(
                icon: QRTypeHelper.getIcon(item.type, item.action),
                backgroundColor: QRTypeHelper.getIconColor(item.type, item.action),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QRTypeHelper.getTitle(item.type, item.code, action: item.action),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UrlHelper.truncateText(item.code, maxLength: 30),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.action} • ${DateFormatter.formatTime(item.timestamp)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButtons(content: item.code),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red[700],
                      ),
                    ),
                    onPressed: () => _deleteItem(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(ScanHistoryItem item) async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context: context,
      title: 'Delete Item',
      content: 'Are you sure you want to delete this item from history?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      await _historyService.removeScan(item.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await DialogHelper.showConfirmationDialog(
      context: context,
      title: 'Clear All History',
      content: 'Are you sure you want to delete all history? This action cannot be undone.',
      confirmText: 'Clear All',
      isDestructive: true,
    );

    if (confirmed) {
      await _historyService.clearHistory();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All history cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
