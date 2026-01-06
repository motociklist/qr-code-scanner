import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../constants/app_styles.dart';
import '../widgets/standard_header.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  String _selectedFilter = 'All';
  bool _showFilters = true;

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
            // White background container for header and filters
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  StandardHeader(
                    title: 'History',
                    trailing: Transform.rotate(
                      angle: _showFilters ? 0 : 3.14159, // 180 degrees in radians
                      child: StandardHeader.createIconButton(
                        iconPath: 'assets/images/history-page/arrow-up.svg',
                        iconWidth: 16,
                        iconHeight: 13,
                        iconColor: const Color(0xFF666666),
                      ),
                    ),
                    onTrailingTap: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                  // Filter tabs
                  if (_showFilters) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChips(
                        filters: const ['All', 'Scanned', 'Created'],
                        selectedFilter: _selectedFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        mainAxisAlignment: MainAxisAlignment.start,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
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
                        final isTodayOrYesterday =
                            groupKey == 'Today' || groupKey == 'Yesterday';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: isTodayOrYesterday ? 24 : 12,
                                top: isTodayOrYesterday
                                    ? 24
                                    : (index > 0 ? 24 : 0),
                              ),
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

  Widget _buildIconWidget(ScanHistoryItem item) {
    final backgroundColor = QRTypeHelper.getIconColor(item.type, item.action);
    final isCreated = item.action == 'Created';

    // For QR code (scanned items that are not WIFI, CONTACT, or Created)
    if (item.action != 'Created' &&
        item.type != 'WIFI' &&
        item.type != 'CONTACT') {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/images/history-page/qr.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      );
    }

    // For other icons (plus, etc.)
    return IconCircle(
      icon: QRTypeHelper.getIcon(item.type, item.action),
      backgroundColor: backgroundColor,
      iconColor: Colors.white,
      iconSize: isCreated ? 15 : 16,
    );
  }

  Widget _buildHistoryItem(ScanHistoryItem item) {
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
              _buildIconWidget(item),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      QRTypeHelper.getTitle(item.type, item.code,
                          action: item.action),
                      style: AppStyles.bodyMediumText,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UrlHelper.truncateText(item.code, maxLength: 30),
                      style: AppStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.action} • ${DateFormatter.formatTime(item.timestamp)}',
                      style: AppStyles.smallText,
                    ),
                  ],
                ),
              ),
              // Action buttons (only copy and share, no delete)
              ActionButtons(content: item.code),
            ],
          ),
        ),
      ),
    );
  }
}
