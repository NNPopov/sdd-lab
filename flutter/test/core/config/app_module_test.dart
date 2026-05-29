import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/core/di/app_module.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concrete instance of the injectable `@module` so its `dio(AppConfig)`
/// factory can be exercised without the generated DI graph.
class _TestAppModule extends AppModule {}

void main() {
  group('AppModule.dio', () {
    test('builds a Dio whose baseUrl is taken from the AppConfig', () {
      const config = AppConfig(baseUrl: 'https://x/api/v1');

      final dio = _TestAppModule().dio(config);

      expect(dio.options.baseUrl, 'https://x/api/v1');
    });
  });
}
