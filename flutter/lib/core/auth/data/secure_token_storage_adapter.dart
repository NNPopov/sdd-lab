import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';
import 'package:flutter_application_1/core/auth/domain/ports/token_storage_port.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TokenStoragePort)
class SecureTokenStorageAdapter implements TokenStoragePort {
  const SecureTokenStorageAdapter(this._storage);

  static const _keyToken = 'auth.access_token';
  static const _keyUsername = 'auth.username';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final token = await _storage.read(key: _keyToken);
    final username = await _storage.read(key: _keyUsername);
    if (token == null || username == null) return null;
    return AuthSession(accessToken: token, username: username);
  }

  @override
  Future<void> write(AuthSession session) async {
    await _storage.write(key: _keyToken, value: session.accessToken);
    await _storage.write(key: _keyUsername, value: session.username);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsername);
  }
}
