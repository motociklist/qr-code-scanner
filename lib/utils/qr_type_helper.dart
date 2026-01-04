import 'package:flutter/material.dart';

class QRTypeHelper {
  static String getTitle(String? type, String code, {String? action}) {
    if (action == 'Shared') {
      if (type == 'CONTACT') {
        return 'Shared contact QR';
      } else if (type == 'WIFI') {
        return 'Shared WiFi QR';
      } else if (type == 'URL' ||
          code.startsWith('http://') ||
          code.startsWith('https://')) {
        return 'Shared website link';
      } else {
        return 'Shared QR code';
      }
    }

    if (type == 'URL' ||
        code.startsWith('http://') ||
        code.startsWith('https://')) {
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
    if (action == 'Shared') {
      return const Color(0xFFFFB86C); // Bright orange для Shared
    }
    if (type == 'WIFI' || type == 'CONTACT' || action == 'Created') {
      return const Color(0xFF77C97E); // Bright green
    }
    return const Color(0xFF7ACBFF); // Bright blue
  }

  static IconData getIcon(String? type, String action) {
    if (action == 'Shared') {
      return Icons.share; // Иконка share для Shared
    }
    if (type == 'WIFI' || type == 'CONTACT' || action == 'Created') {
      return Icons.add;
    }
    return Icons.qr_code_2;
  }

  static String getActivityText(String? type, String action, String code) {
    final isUrl = code.startsWith('http://') || code.startsWith('https://');
    final isWifi = type == 'WIFI';
    final isContact = type == 'CONTACT';

    if (action == 'Shared') {
      if (isContact) {
        return 'Shared contact QR';
      } else if (isWifi) {
        return 'Shared WiFi QR';
      } else if (isUrl) {
        return 'Shared website link';
      } else {
        return 'Shared QR code';
      }
    }

    if (action == 'Created') {
      if (isWifi) {
        return 'Created WiFi QR';
      } else if (isContact) {
        return 'Created contact QR';
      }
    }

    if (isUrl) {
      return 'Scanned website link';
    }

    return 'Scanned QR code';
  }
}
