import 'dart:io';

import 'package:flutter_application_1/core/i18n/hive_locale_storage_adapter.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late HiveLocaleStorageAdapter adapter;
  late _MockAppLogger mockLogger;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    mockLogger = _MockAppLogger();
    adapter = HiveLocaleStorageAdapter(mockLogger);
  });

  tearDown(() async {
    await Hive.close();
  });

  group('saveLocale()', () {
    test('stores "en-US" in box for AppLocale.enUs', () async {
      await adapter.saveLocale(AppLocale.enUs);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'en-US');
    });

    test('stores "ru-RU" in box for AppLocale.ruRu', () async {
      await adapter.saveLocale(AppLocale.ruRu);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'ru-RU');
    });

    test('stores "es-ES" in box for AppLocale.esEs', () async {
      await adapter.saveLocale(AppLocale.esEs);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'es-ES');
    });

    test('stores "uk-UA" in box for AppLocale.ukUa', () async {
      await adapter.saveLocale(AppLocale.ukUa);
      final box = await Hive.openBox<String>('locale');
      expect(box.get('locale'), 'uk-UA');
    });
  });

  group('loadLocale()', () {
    test('returns AppLocale.ruRu after saveLocale(AppLocale.ruRu)', () async {
      await adapter.saveLocale(AppLocale.ruRu);
      final result = await adapter.loadLocale();
      expect(result, AppLocale.ruRu);
    });

    test('returns null when box is empty', () async {
      final result = await adapter.loadLocale();
      expect(result, isNull);
    });

    test('returns null for unknown language code', () async {
      final box = await Hive.openBox<String>('locale');
      await box.put('locale', 'de');
      final result = await adapter.loadLocale();
      expect(result, isNull);
    });

    test('returns AppLocale.esEs after saveLocale(AppLocale.esEs)', () async {
      await adapter.saveLocale(AppLocale.esEs);
      final result = await adapter.loadLocale();
      expect(result, AppLocale.esEs);
    });

    test('returns AppLocale.ukUa after saveLocale(AppLocale.ukUa)', () async {
      await adapter.saveLocale(AppLocale.ukUa);
      final result = await adapter.loadLocale();
      expect(result, AppLocale.ukUa);
    });
  });
}
