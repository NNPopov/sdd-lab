import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/create_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/paginated_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/update_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/dto/revise_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_result_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_response_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'posts_api_client.g.dart';

@RestApi()
abstract class PostsApiClient {
  factory PostsApiClient(Dio dio) = _PostsApiClient;

  @GET('/posts')
  Future<PaginatedPostsDto> getPosts({
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });

  @GET('/{username}/posts')
  Future<PaginatedPostsDto> getUserPosts(
    @Path('username') String username, {
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });

  @POST('/{username}/post')
  Future<PostDto> createPost(
    @Path('username') String username,
    @Body() CreatePostRequestDto body,
  );

  @GET('/{username}/post/{id}')
  Future<PostDto> getPost(
    @Path('username') String username,
    @Path('id') int id,
  );

  @PATCH('/{username}/post/{id}')
  Future<void> patchPost(
    @Path('username') String username,
    @Path('id') int id,
    @Body() UpdatePostRequestDto body,
  );

  @DELETE('/{username}/post/{id}')
  Future<void> deletePost(
    @Path('username') String username,
    @Path('id') int id,
  );

  @DELETE('/{username}/db_post/{id}')
  Future<void> eraseDbPost(
    @Path('username') String username,
    @Path('id') int id,
  );

  @GET('/posts/pending')
  Future<PendingPostsDto> getPendingPosts({
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });

  @POST('/posts/{post_uuid}/moderate')
  Future<ModeratePostResultDto> moderatePost(
    @Path('post_uuid') String postUuid,
    @Body() ModeratePostRequestDto body,
  );

  @PATCH('/posts/{post_uuid}/revise')
  Future<void> revisePost(
    @Path('post_uuid') String postUuid,
    @Body() RevisePostRequestDto body,
  );

  @GET('/posts/{post_uuid}/moderation-log')
  Future<ModerationLogResponseDto> getModerationLog(
    @Path('post_uuid') String postUuid,
  );
}
