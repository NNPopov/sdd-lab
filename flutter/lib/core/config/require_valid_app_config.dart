import 'package:flutter_application_1/core/config/app_config.dart';

/// Throws [StateError] when [AppConfig.baseUrl] is empty — i.e. the build was
/// run without `--dart-define-from-file`. The message names the missing flag
/// and lists every valid config file so the developer fixes it in one read.
void requireValidAppConfig(AppConfig config) {
  if (config.baseUrl.isNotEmpty) return;
  throw StateError(
    'BASE_URL is empty: the app was built without '
    '--dart-define-from-file. Re-run with one of:\n'
    '  flutter/config/local-web.json\n'
    '  flutter/config/local-android-emulator.json\n'
    '  flutter/config/local-ios-simulator.json\n'
    '  flutter/config/local-desktop.json\n'
    '  flutter/config/prod-web.json\n'
    'e.g. flutter run --dart-define-from-file=flutter/config/local-desktop.json',
  );
}
