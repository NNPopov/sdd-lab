import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AppLogger)
class ConsoleLoggerAdapter implements AppLogger {
  @override
  void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }

  @override
  void info(String message) {
    debugPrint('[INFO] $message');
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[WARNING] $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) debugPrint('  stack: $stackTrace');
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) debugPrint('  stack: $stackTrace');
  }
}
