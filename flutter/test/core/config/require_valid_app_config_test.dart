import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/core/config/require_valid_app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('requireValidAppConfig', () {
    test('returns normally for a non-empty baseUrl', () {
      const config = AppConfig(baseUrl: 'https://x/api/v1');

      expect(() => requireValidAppConfig(config), returnsNormally);
    });

    test(
      'throws StateError whose message names the fix when baseUrl is empty',
      () {
        const config = AppConfig(baseUrl: '');

        expect(
          () => requireValidAppConfig(config),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('--dart-define-from-file'),
                contains('flutter/config/'),
                contains('local-desktop.json'),
              ),
            ),
          ),
        );
      },
    );
  });
}
