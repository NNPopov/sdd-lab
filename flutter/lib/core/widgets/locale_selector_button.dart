import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LocaleSelectorButton extends StatelessWidget {
  const LocaleSelectorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, AppLocale>(
      builder: (context, locale) => TextButton(
        onPressed: () => _showLocaleSheet(context, locale),
        child: Text(locale.languageTag.split('-').first.toUpperCase()),
      ),
    );
  }

  void _showLocaleSheet(BuildContext context, AppLocale current) {
    final cubit = context.read<LocaleCubit>();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => _LocaleBottomSheet(
          current: current,
          onSelect: (locale) {
            unawaited(cubit.setLocale(locale));
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }
}

class _LocaleBottomSheet extends StatelessWidget {
  const _LocaleBottomSheet({required this.current, required this.onSelect});

  final AppLocale current;
  final ValueChanged<AppLocale> onSelect;

  static const Map<AppLocale, String> _nativeNames = {
    AppLocale.enUs: 'English',
    AppLocale.ruRu: 'Русский',
    AppLocale.esEs: 'Español',
    AppLocale.ukUa: 'Українська',
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: AppLocale.values
            .map(
              (locale) => ListTile(
                title: Text(_nativeNames[locale] ?? locale.languageTag),
                trailing: locale == current ? const Icon(Icons.check) : null,
                onTap: () => onSelect(locale),
              ),
            )
            .toList(),
      ),
    );
  }
}
