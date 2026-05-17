import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/auth/application/auth_event.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/auth/domain/ports/auth_api_port.dart';
import 'package:flutter_application_1/core/auth/domain/ports/token_storage_port.dart';
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._api, this._storage, this._tokens)
    : super(const AuthUnknown());

  final AuthApiPort _api;
  final TokenStoragePort _storage;
  final TokenHolder _tokens;

  final _events = StreamController<AuthEvent>.broadcast();
  Stream<AuthEvent> get events => _events.stream;

  Future<void> bootstrap() async {
    final session = await _storage.read();
    if (session == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    _tokens.current = session.accessToken;
    final meResult = await _api.getCurrentUser();
    await meResult.fold<Future<void>>(
      (f) async {
        _tokens.release();
        await _storage.clear();
        emit(const AuthUnauthenticated());
      },
      (me) async => emit(AuthAuthenticated(currentUser: me)),
    );
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    debugPrint('[LOGIN] start');
    emit(const AuthAuthenticating());
    final result = await _api.login(username: username, password: password);
    await result.fold<Future<void>>(
      (failure) async {
        debugPrint('[LOGIN] login failed: $failure');
        emit(AuthError(failure));
      },
      (session) async {
        debugPrint('[LOGIN] login OK, token len=${session.accessToken.length}');
        await _storage.write(session);
        _tokens.current = session.accessToken;
        debugPrint('[LOGIN] token set in holder, calling /me');
        final meResult = await _api.getCurrentUser();
        debugPrint('[LOGIN] /me result: $meResult');
        meResult.fold(
          (f) {
            debugPrint('[LOGIN] /me failed: $f, emitting Authenticated()');
            emit(const AuthAuthenticated());
          },
          (me) {
            debugPrint(
              '[LOGIN] /me OK, user=${me.username}, emitting Authenticated(me)',
            );
            emit(AuthAuthenticated(currentUser: me));
          },
        );
      },
    );
    debugPrint('[LOGIN] end, state=${state.runtimeType}');
  }

  Future<void> logout() async {
    if (state is! AuthAuthenticated) return;
    await _api.logout();
    _tokens.release();
    await _storage.clear();
    emit(const AuthUnauthenticated());
  }

  /// Вызывается AuthInterceptor при 401, либо напрямую при удалении аккаунта.
  /// [notifyUser] — если false, SessionExpiredEvent не отправляется (нужно
  /// когда caller показывает собственный snackbar, например "Account deleted").
  Future<void> forceLogout({bool notifyUser = true}) async {
    _tokens.release();
    await _storage.clear();
    if (state is! AuthUnauthenticated) {
      if (notifyUser) _events.add(SessionExpiredEvent());
      emit(const AuthUnauthenticated());
    }
  }

  CurrentUser? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.currentUser : null;
  }

  bool isMe(String username) => currentUser?.username == username;

  @override
  Future<void> close() {
    unawaited(_events.close());
    return super.close();
  }
}
