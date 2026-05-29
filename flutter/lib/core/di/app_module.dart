import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/config/app_config.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio dio(AppConfig config) => DioClient.create(baseUrl: config.baseUrl);
}
