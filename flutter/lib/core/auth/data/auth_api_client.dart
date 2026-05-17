import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/auth/data/dto/current_user_dto.dart';
import 'package:flutter_application_1/core/auth/data/dto/token_response_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_client.g.dart';

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String? baseUrl}) = _AuthApiClient;

  @POST('/login')
  @FormUrlEncoded()
  Future<TokenResponseDto> login({
    @Field('username') required String username,
    @Field('password') required String password,
    @Field('grant_type') String grantType = 'password',
  });

  @POST('/logout')
  Future<void> logout();

  @GET('/user/me/')
  Future<CurrentUserDto> getCurrentUser();
}
