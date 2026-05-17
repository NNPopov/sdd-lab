import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart';
import 'package:flutter_application_1/core/auth/infrastructure/auth_interceptor.dart';
import 'package:flutter_application_1/core/auth/infrastructure/session_expired_listener.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/core/i18n/locale_cubit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/core/routing/app_router.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  unawaited(
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        await Hive.initFlutter();
        configureDependencies();

        final logger = getIt<AppLogger>();

        FlutterError.onError = (details) {
          logger.error(
            'Flutter framework error',
            error: details.exception,
            stackTrace: details.stack,
          );
          FlutterError.presentError(details);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          logger.error(
            'Uncaught platform error',
            error: error,
            stackTrace: stack,
          );
          return true;
        };

        // Wire AuthInterceptor after DI to break circular dependency:
        // AuthInterceptor → TokenHolder ← AuthCubit → AuthApiAdapter → Dio.
        final dio = getIt<Dio>();
        final tokens = getIt<TokenHolder>();
        final authCubit = getIt<AuthCubit>();
        dio.interceptors.add(
          AuthInterceptor(tokens, () => unawaited(authCubit.forceLogout())),
        );

        await authCubit.bootstrap();
        await getIt<LocaleCubit>().init();

        runApp(App());
      },
      (error, stack) {
        // runZonedGuarded catches errors that escape even PlatformDispatcher.
        // At this point DI may not be ready, so we fall back to FlutterError.
        FlutterError.reportError(
          FlutterErrorDetails(exception: error, stack: stack),
        );
      },
    ),
  );
}

class App extends StatelessWidget {
  App({super.key});

  final _router = AppRouter(
    authGuard: getIt<AuthGuard>(),
    permissionCubit: getIt<PermissionCubit>(),
  );
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<PermissionCubit>()),
      ],
      child: BlocProvider.value(
        value: getIt<LocaleCubit>(),
        child: TranslationProvider(
          child: _AppContent(
            router: _router,
            scaffoldMessengerKey: _scaffoldMessengerKey,
          ),
        ),
      ),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent({
    required this.router,
    required this.scaffoldMessengerKey,
  });

  final AppRouter router;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: context.t.app.title,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: LocaleSettings.currentLocale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router.config(),
      builder: (context, child) => SessionExpiredListener(
        scaffoldMessengerKey: scaffoldMessengerKey,
        child: child ?? const SizedBox(),
      ),
    );
  }
}
