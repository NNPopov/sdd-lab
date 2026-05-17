import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/data/auth_api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AuthModule {
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  AuthApiClient authApiClient(Dio dio) => AuthApiClient(dio);
}
