import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:injectable/injectable.dart';

@module
abstract class PostsFeatureModule {
  @lazySingleton
  PostsApiClient postsApiClient(Dio dio) => PostsApiClient(dio);
}
