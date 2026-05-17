import 'package:injectable/injectable.dart';

/// In-memory хранилище текущего access token. Читается синхронно.
/// Источник истины для AuthInterceptor.
/// Обновляется AuthCubit при login/bootstrap/logout.
@lazySingleton
class TokenHolder {
  String? current;

  void release() => current = null;
}
