class QRParser {
  static QRType detectType(String code) {
    // URL
    if (code.startsWith('http://') || code.startsWith('https://')) {
      return QRType.url;
    }

    // Phone
    if (code.startsWith('tel:')) {
      return QRType.phone;
    }

    // Email
    if (code.startsWith('mailto:')) {
      return QRType.email;
    }

    // WiFi
    if (code.startsWith('WIFI:')) {
      return QRType.wifi;
    }

    // Contact (vCard)
    if (code.startsWith('BEGIN:VCARD')) {
      return QRType.contact;
    }

    // SMS
    if (code.startsWith('sms:')) {
      return QRType.sms;
    }

    // Default to text
    return QRType.text;
  }

  static Map<String, String> parseWiFi(String code) {
    final result = <String, String>{};

    // Format: WIFI:T:WPA;S:NetworkName;P:Password;;
    final parts = code.replaceFirst('WIFI:', '').split(';');

    for (final part in parts) {
      if (part.isEmpty) continue;
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        result[keyValue[0]] = keyValue[1];
      }
    }

    return result;
  }

  static Map<String, String> parseContact(String vcard) {
    final result = <String, String>{};

    final lines = vcard.split('\n');
    for (final line in lines) {
      if (line.startsWith('FN:')) {
        result['name'] = line.substring(3).trim();
      } else if (line.startsWith('TEL:')) {
        result['phone'] = line.substring(4).trim();
      } else if (line.startsWith('EMAIL:')) {
        result['email'] = line.substring(6).trim();
      } else if (line.startsWith('ORG:')) {
        result['organization'] = line.substring(4).trim();
      } else if (line.startsWith('ADR:')) {
        result['address'] = line.substring(4).trim();
      }
    }

    return result;
  }

  static Map<String, String> parseEmail(String mailto) {
    final result = <String, String>{};

    // Format: mailto:email?subject=Subject&body=Body
    final uri = Uri.parse(mailto);
    result['email'] = uri.path;
    result['subject'] = uri.queryParameters['subject'] ?? '';
    result['body'] = uri.queryParameters['body'] ?? '';

    return result;
  }

  static String parsePhone(String tel) {
    return tel.replaceFirst('tel:', '');
  }
}

enum QRType {
  url,
  text,
  phone,
  email,
  contact,
  wifi,
  sms,
}

