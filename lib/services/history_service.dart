import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_history_item.dart';

class HistoryService extends ChangeNotifier {
  static const String _key = 'scan_history';
  static HistoryService? _instance;

  HistoryService._internal();

  /// Singleton instance - consistent with other services
  static HistoryService get instance {
    _instance ??= HistoryService._internal();
    return _instance!;
  }

  /// Factory constructor for backward compatibility
  factory HistoryService() => instance;

  List<ScanHistoryItem> _history = [];
  bool _isLoaded = false;

  List<ScanHistoryItem> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _history = jsonList
            .map((json) =>
                ScanHistoryItem.fromJson(json as Map<String, dynamic>))
            .toList();
        // Sort by timestamp descending
        _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      _isLoaded = true;
    } catch (e) {
      _history = [];
      _isLoaded = true;
    }
  }

  Future<void> addScan(ScanHistoryItem item) async {
    await loadHistory();
    _history.insert(0, item);
    // Keep only last 200 items
    if (_history.length > 200) {
      _history = _history.take(200).toList();
    }
    await _saveToStorage();
    notifyListeners(); // Уведомляем всех слушателей об изменении
  }

  Future<void> removeScan(String id) async {
    await loadHistory();
    _history.removeWhere((item) => item.id == id);
    await _saveToStorage();
    notifyListeners(); // Уведомляем всех слушателей об изменении
  }

  Future<void> clearHistory() async {
    await loadHistory();
    _history.clear();
    await _saveToStorage();
    notifyListeners(); // Уведомляем всех слушателей об изменении
  }

  /// Перезагрузить историю из хранилища (например, после изменений из другого места)
  Future<void> reloadHistory() async {
    _isLoaded = false;
    await loadHistory();
    notifyListeners();
  }

  ScanHistoryItem? getScanById(String id) {
    try {
      return _history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _history.map((item) => item.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}
