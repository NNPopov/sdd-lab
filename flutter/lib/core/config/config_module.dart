import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:injectable/injectable.dart';

@module
abstract class ConfigModule {
  @lazySingleton
  AppConfig get appConfig => appConfigFromEnvironment;
}
