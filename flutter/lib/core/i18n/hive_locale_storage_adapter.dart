import 'package:flutter_application_1/core/i18n/locale_storage_port.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LocaleStoragePort)
class HiveLocaleStorageAdapter implements LocaleStoragePort {
  HiveLocaleStorageAdapter(this._logger);

  final AppLogger _logger;

  static const _boxName = 'locale';
  static const _key = 'locale';

  @override
  Future<void> saveLocale(AppLocale locale) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(_key, locale.languageTag);
    } catch (e, st) {
      _logger.error(
        'HiveLocaleStorageAdapter.saveLocale failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<AppLocale?> loadLocale() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final code = box.get(_key);
      if (code == null) return null;
      return _parseLocale(code);
    } catch (e, st) {
      _logger.error(
        'HiveLocaleStorageAdapter.loadLocale failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  AppLocale? _parseLocale(String code) {
    for (final l in AppLocale.values) {
      if (l.languageTag == code) return l;
    }
    return null;
  }
}
