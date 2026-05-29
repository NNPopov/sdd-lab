import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('constructs and exposes its baseUrl', () {
      const config = AppConfig(baseUrl: 'https://x/api/v1');

      expect(config.baseUrl, 'https://x/api/v1');
    });

    test('values equal when baseUrl matches', () {
      const a = AppConfig(baseUrl: 'https://x/api/v1');
      const b = AppConfig(baseUrl: 'https://x/api/v1');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test(
      'appConfigFromEnvironment resolves to empty baseUrl with no '
      '--dart-define (the default under flutter test)',
      () {
        expect(appConfigFromEnvironment.baseUrl, '');
      },
    );
  });
}
