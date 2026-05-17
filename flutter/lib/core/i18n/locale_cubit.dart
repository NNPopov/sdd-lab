import 'package:flutter_application_1/core/i18n/locale_storage_port.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocaleCubit extends Cubit<AppLocale> {
  LocaleCubit(this._storage) : super(LocaleSettings.currentLocale);

  final LocaleStoragePort _storage;

  Future<void> init() async {
    final saved = await _storage.loadLocale();
    if (saved != null) await setLocale(saved);
  }

  Future<void> setLocale(AppLocale locale) async {
    final applied = await LocaleSettings.setLocale(locale);
    await _storage.saveLocale(applied);
    emit(applied);
  }

  Future<void> useDeviceLocale() async {
    final locale = await LocaleSettings.useDeviceLocale();
    emit(locale);
  }
}
