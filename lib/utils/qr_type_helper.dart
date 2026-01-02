import 'package:flutter/material.dart';

class QRTypeHelper {
  static String getTitle(String? type, String code) {
    if (type == 'URL' || code.startsWith('http://') || code.startsWith('https://')) {
      return 'Website Link';
    } else if (type == 'WIFI') {
      return 'WiFi Network';
    } else if (type == 'CONTACT') {
      return 'Contact Info';
    } else {
      return 'Text Message';
    }
  }

  static Color getIconColor(String? type, String action) {
    if (type == 'WIFI' || type == 'CONTACT' || action == 'Created') {
      return const Color(0xFFC8E6C9); // Light green
    }
    return const Color(0xFFBBDEFB); // Light blue
  }

  static IconData getIcon(String? type, String action) {
    if (type == 'WIFI' || type == 'CONTACT' || action == 'Created') {
      return Icons.add;
    }
    return Icons.qr_code_2;
  }
}

