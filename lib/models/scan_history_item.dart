class ScanHistoryItem {
  final String id;
  final String code;
  final DateTime timestamp;
  final String? type; // URL, TEXT, WIFI, CONTACT, etc.
  final String action; // 'Scanned' or 'Created'

  ScanHistoryItem({
    required this.id,
    required this.code,
    required this.timestamp,
    this.type,
    this.action = 'Scanned',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'action': action,
    };
  }

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] as String,
      code: json['code'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String?,
      action: json['action'] as String? ?? 'Scanned',
    );
  }
}

