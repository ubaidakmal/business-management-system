import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[BMS] $message');
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[BMS] ERROR: $message${error == null ? '' : ' | $error'}');
    }
  }
}
