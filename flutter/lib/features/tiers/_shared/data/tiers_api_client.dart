import 'package:dio/dio.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/create_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/paginated_tiers_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/tier_dto.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/dto/edit_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/dto/tier_detail_dto.dart';
import 'package:retrofit/retrofit.dart';

part 'tiers_api_client.g.dart';

@RestApi()
abstract class TiersApiClient {
  factory TiersApiClient(Dio dio) = _TiersApiClient;

  @GET('/tiers')
  Future<PaginatedTiersDto> getTiers({
    @Query('page') required int page,
    @Query('items_per_page') required int perPage,
  });

  @POST('/tier')
  Future<TierDto> createTier(@Body() CreateTierRequestDto body);

  @GET('/tier/{name}')
  Future<TierDetailDto> getTier(@Path('name') String name);

  @PATCH('/tier/{name}')
  Future<void> patchTier(
    @Path('name') String name,
    @Body() EditTierRequestDto body,
  );

  @DELETE('/tier/{name}')
  Future<void> deleteTier(@Path('name') String name);
}
