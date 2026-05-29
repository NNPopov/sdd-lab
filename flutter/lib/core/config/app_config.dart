import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';

/// Immutable application configuration resolved at compile time.
///
/// Holds the single value the app needs to talk to its backend: [baseUrl].
/// Extend by adding one field here (and one key in each `flutter/config/*.json`).
@freezed
sealed class AppConfig with _$AppConfig {
  const factory AppConfig({required String baseUrl}) = _AppConfig;
}

/// Compile-time configuration injected via `--dart-define-from-file`.
///
/// `String.fromEnvironment` is a `const`-evaluable constructor, so this is a
/// valid compile-time constant. It reads `BASE_URL` with **no** default, so a
/// build run without `--dart-define-from-file` resolves [AppConfig.baseUrl] to
/// the empty string — the startup guard (`requireValidAppConfig`) turns that
/// into a loud failure rather than a silent fallback URL.
const appConfigFromEnvironment = AppConfig(
  baseUrl: String.fromEnvironment('BASE_URL'),
);
