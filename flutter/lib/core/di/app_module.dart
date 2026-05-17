import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AppModule {
  @lazySingleton
  Dio dio() => DioClient.create(baseUrl: 'http://127.0.0.1:8000/api/v1');
}
