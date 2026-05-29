import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/core/config/require_valid_app_config.dart';
import 'package:flutter_application_1/core/di/app_module.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concrete instance of the injectable `@module` so its `dio(AppConfig)`
/// factory can be exercised without the generated DI graph.
class _TestAppModule extends AppModule {}

void main() {
  group('0056 app_config_per_platform — outside-in', () {
    // Scenario 1: configured baseUrl flows through to the Dio client.
    test('configured baseUrl flows through to the Dio client', () {
      const config = AppConfig(baseUrl: 'https://x/api/v1');

      final Dio dio = _TestAppModule().dio(config);

      expect(dio.options.baseUrl, 'https://x/api/v1');
      // The startup guard accepts a non-empty config without throwing.
      expect(() => requireValidAppConfig(config), returnsNormally);
    });

    // Scenario 2: missing/empty config fails loud at the startup guard.
    test('missing/empty config fails loud at the startup guard', () {
      // The value String.fromEnvironment('BASE_URL') resolves to when no
      // --dart-define-from-file flag was passed.
      const config = AppConfig(baseUrl: '');

      StateError? thrown;
      try {
        requireValidAppConfig(config);
      } on StateError catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull, reason: 'empty baseUrl must throw StateError');
      final message = thrown!.message;
      expect(message, contains('--dart-define-from-file'));
      expect(message, contains('flutter/config/'));
      expect(message, contains('local-desktop.json'));
    });
  });
}
