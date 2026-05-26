import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/create_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/paginated_users_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/update_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/dto/user_tier_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/paginated_tier_options_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/update_user_tier_request_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'users_api_client.g.dart';

@RestApi()
abstract class UsersApiClient {
  factory UsersApiClient(Dio dio) = _UsersApiClient;

  @GET('/users')
  Future<PaginatedUsersDto> getUsers({
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });

  @POST('/user')
  Future<UserDto> createUser(@Body() CreateUserRequestDto body);

  @GET('/user/{user_id}')
  Future<UserDto> getUser(@Path('user_id') int userId);

  @PATCH('/user/{user_id}')
  Future<void> updateUser(
    @Path('user_id') int userId,
    @Body() UpdateUserRequestDto body,
  );

  @DELETE('/user/{user_id}')
  Future<void> deleteUser(@Path('user_id') int userId);

  @DELETE('/db_user/{username}')
  Future<void> eraseDbUser(@Path('username') String username);

  @GET('/user/{username}/tier')
  Future<UserTierDto> getUserTier(@Path('username') String username);

  @GET('/tiers')
  Future<PaginatedTierOptionsDto> getTiersForSelection({
    @Query('page') int page = 1,
    @Query('items_per_page') int perPage = 100,
  });

  @PATCH('/user/{username}/tier')
  Future<void> patchUserTier(
    @Path('username') String username,
    @Body() UpdateUserTierRequestDto body,
  );

  @PATCH('/user/{username}/assign-moderator')
  Future<void> assignModerator(@Path('username') String username);

  @PATCH('/user/{username}/revoke-moderator')
  Future<void> revokeModerator(@Path('username') String username);
}
