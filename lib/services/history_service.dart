import '../models/scan_history_item.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  final List<ScanHistoryItem> _history = [];

  List<ScanHistoryItem> get history => List.unmodifiable(_history);

  void addScan(ScanHistoryItem item) {
    _history.insert(0, item);
    if (_history.length > 100) {
      _history.removeLast();
    }
  }

  void removeScan(String id) {
    _history.removeWhere((item) => item.id == id);
  }

  void clearHistory() {
    _history.clear();
  }

  ScanHistoryItem? getScanById(String id) {
    try {
      return _history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}

