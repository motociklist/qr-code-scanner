import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_qr_code.dart';

class SavedQRService extends ChangeNotifier {
  static const String _key = 'saved_qr_codes';
  static SavedQRService? _instance;
  List<SavedQRCode> _savedCodes = [];
  bool _isLoaded = false;

  SavedQRService._();

  static SavedQRService get instance {
    _instance ??= SavedQRService._();
    return _instance!;
  }

  List<SavedQRCode> get savedCodes => List.unmodifiable(_savedCodes);

  Future<void> loadSavedCodes() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _savedCodes = jsonList
            .map((json) => SavedQRCode.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _savedCodes = [];
      _isLoaded = true;
    }
  }

  Future<void> saveCode(SavedQRCode code) async {
    await loadSavedCodes();
    _savedCodes.add(code);
    await _saveToStorage();
    notifyListeners(); // Уведомляем всех слушателей об изменении
  }

  Future<void> updateCode(SavedQRCode code) async {
    await loadSavedCodes();
    final index = _savedCodes.indexWhere((c) => c.id == code.id);
    if (index != -1) {
      _savedCodes[index] = code;
      await _saveToStorage();
      notifyListeners(); // Уведомляем всех слушателей об изменении
    }
  }

  Future<void> deleteCode(String id) async {
    await loadSavedCodes();
    _savedCodes.removeWhere((code) => code.id == id);
    await _saveToStorage();
    notifyListeners(); // Уведомляем всех слушателей об изменении
  }

  Future<void> incrementViewCount(String id) async {
    await loadSavedCodes();
    final index = _savedCodes.indexWhere((c) => c.id == id);
    if (index != -1) {
      _savedCodes[index] = _savedCodes[index].copyWith(
        viewCount: _savedCodes[index].viewCount + 1,
      );
      await _saveToStorage();
      notifyListeners(); // Уведомляем всех слушателей об изменении
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _savedCodes.map((code) => code.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  List<SavedQRCode> getCodesByType(String? type) {
    if (type == null || type == 'All') {
      return List.unmodifiable(_savedCodes);
    }
    return List.unmodifiable(_savedCodes.where((code) => code.type == type).toList());
  }

  SavedQRCode? getCodeByContent(String content) {
    try {
      return _savedCodes.firstWhere((code) => code.content == content);
    } catch (e) {
      return null;
    }
  }

  Future<void> incrementViewCountByContent(String content) async {
    await loadSavedCodes();
    final code = getCodeByContent(content);
    if (code != null) {
      await incrementViewCount(code.id);
    }
  }
}

