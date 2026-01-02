import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_qr_code.dart';

class SavedQRService {
  static const String _key = 'saved_qr_codes';
  static SavedQRService? _instance;
  List<SavedQRCode> _savedCodes = [];

  SavedQRService._();

  static SavedQRService get instance {
    _instance ??= SavedQRService._();
    return _instance!;
  }

  List<SavedQRCode> get savedCodes => List.unmodifiable(_savedCodes);

  Future<void> loadSavedCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      _savedCodes = jsonList
          .map((json) => SavedQRCode.fromJson(json as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> saveCode(SavedQRCode code) async {
    _savedCodes.add(code);
    await _saveToStorage();
  }

  Future<void> updateCode(SavedQRCode code) async {
    final index = _savedCodes.indexWhere((c) => c.id == code.id);
    if (index != -1) {
      _savedCodes[index] = code;
      await _saveToStorage();
    }
  }

  Future<void> deleteCode(String id) async {
    _savedCodes.removeWhere((code) => code.id == id);
    await _saveToStorage();
  }

  Future<void> incrementViewCount(String id) async {
    final index = _savedCodes.indexWhere((c) => c.id == id);
    if (index != -1) {
      _savedCodes[index] = _savedCodes[index].copyWith(
        viewCount: _savedCodes[index].viewCount + 1,
      );
      await _saveToStorage();
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
}

