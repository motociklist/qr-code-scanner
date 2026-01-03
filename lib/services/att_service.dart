import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';

// Conditional import for Platform - only works on mobile
import 'dart:io' if (dart.library.html) 'dart:html' as io;

// Helper to check if platform is iOS (only works on mobile)
bool _isIOS() {
  if (kIsWeb) return false;
  // On web, io will be dart:html which doesn't have Platform
  // On mobile, io will be dart:io which has Platform.isIOS
  try {
    // ignore: avoid_dynamic_calls
    return (io.Platform as dynamic).isIOS == true;
  } catch (e) {
    // On web, Platform doesn't exist, so return false
    return false;
  }
}

enum ATTStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
}

class ATTService {
  static ATTService? _instance;
  ATTService._();

  static ATTService get instance {
    _instance ??= ATTService._();
    return _instance!;
  }

  /// Request ATT permission (iOS only)
  Future<ATTStatus> requestPermission() async {
    if (kIsWeb) {
      return ATTStatus.authorized; // Web doesn't need ATT
    }
    if (!_isIOS()) {
      return ATTStatus.authorized; // Android doesn't need ATT
    }

    try {
      final status = await Permission.appTrackingTransparency.status;

      if (status.isDenied) {
        final result = await Permission.appTrackingTransparency.request();
        return _mapPermissionStatus(result);
      }

      return _mapPermissionStatus(status);
    } catch (e) {
      debugPrint('Error requesting ATT permission: $e');
      return ATTStatus.denied;
    }
  }

  /// Get current ATT status
  Future<ATTStatus> getStatus() async {
    if (kIsWeb) {
      return ATTStatus.authorized; // Web doesn't need ATT
    }
    if (!_isIOS()) {
      return ATTStatus.authorized;
    }

    try {
      final status = await Permission.appTrackingTransparency.status;
      return _mapPermissionStatus(status);
    } catch (e) {
      debugPrint('Error getting ATT status: $e');
      return ATTStatus.denied;
    }
  }

  /// Map PermissionStatus to ATTStatus
  ATTStatus _mapPermissionStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return ATTStatus.denied;
      case PermissionStatus.restricted:
        return ATTStatus.restricted;
      case PermissionStatus.granted:
        return ATTStatus.authorized;
      case PermissionStatus.limited:
        return ATTStatus.authorized;
      case PermissionStatus.permanentlyDenied:
        return ATTStatus.denied;
      default:
        return ATTStatus.notDetermined;
    }
  }

  /// Get IDFA (iOS only)
  Future<String?> getIDFA() async {
    if (kIsWeb) {
      return null; // Web doesn't have IDFA
    }
    if (!_isIOS()) {
      return null;
    }

    try {
      // Note: Getting IDFA directly requires native code
      // This is a placeholder - you'll need to implement native code
      // or use a package that provides IDFA
      final status = await getStatus();
      if (status == ATTStatus.authorized) {
        // Return a placeholder - implement native code to get actual IDFA
        return 'idfa_placeholder';
      }
      return null;
    } catch (e) {
      debugPrint('Error getting IDFA: $e');
      return null;
    }
  }
}
