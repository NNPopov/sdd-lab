import 'package:flutter_application_1/core/auth/domain/entities/auth_session.dart';

abstract class TokenStoragePort {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}
