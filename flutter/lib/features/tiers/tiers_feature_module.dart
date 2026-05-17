import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class TiersFeatureModule {
  @lazySingleton
  TiersApiClient tiersApiClient(Dio dio) => TiersApiClient(dio);
}
