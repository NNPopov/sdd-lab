import 'package:flutter_application_1/core/i18n/translations.g.dart';

abstract class LocaleStoragePort {
  Future<void> saveLocale(AppLocale locale);
  Future<AppLocale?> loadLocale();
}
