import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class UsersFeatureModule {
  @lazySingleton
  UsersApiClient usersApiClient(Dio dio) => UsersApiClient(dio);
}
