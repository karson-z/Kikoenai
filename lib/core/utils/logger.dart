import 'package:flutter/foundation.dart';

class Log {
  static void d(String message, {String tag = 'APP'}) {
    debugPrint('[D][$tag] $message');
  }

  static void i(String message, {String tag = 'APP'}) {
    debugPrint('[I][$tag] $message');
  }

  static void w(String message, {String tag = 'APP'}) {
    debugPrint('[W][$tag] $message');
  }

  static void e(Object error, {String tag = 'APP'}) {
    debugPrint('[E][$tag] $error');
  }
}