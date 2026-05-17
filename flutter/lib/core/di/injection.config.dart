// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart'
    as _i657;
import 'package:flutter_application_1/core/auth/auth_module.dart' as _i136;
import 'package:flutter_application_1/core/auth/data/auth_api_adapter.dart'
    as _i377;
import 'package:flutter_application_1/core/auth/data/auth_api_client.dart'
    as _i53;
import 'package:flutter_application_1/core/auth/data/secure_token_storage_adapter.dart'
    as _i761;
import 'package:flutter_application_1/core/auth/domain/ports/auth_api_port.dart'
    as _i734;
import 'package:flutter_application_1/core/auth/domain/ports/token_storage_port.dart'
    as _i268;
import 'package:flutter_application_1/core/auth/infrastructure/auth_guard.dart'
    as _i553;
import 'package:flutter_application_1/core/auth/infrastructure/token_holder.dart'
    as _i623;
import 'package:flutter_application_1/core/di/app_module.dart' as _i690;
import 'package:flutter_application_1/core/i18n/hive_locale_storage_adapter.dart'
    as _i270;
import 'package:flutter_application_1/core/i18n/locale_cubit.dart' as _i1073;
import 'package:flutter_application_1/core/i18n/locale_storage_port.dart'
    as _i910;
import 'package:flutter_application_1/core/logging/domain/app_logger.dart'
    as _i672;
import 'package:flutter_application_1/core/logging/infrastructure/console_logger_adapter.dart'
    as _i896;
import 'package:flutter_application_1/core/rbac/permission_cubit.dart'
    as _i1041;
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart'
    as _i292;
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart'
    as _i964;
import 'package:flutter_application_1/features/posts/_shared/data/moderation_log_adapter.dart'
    as _i139;
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart'
    as _i72;
import 'package:flutter_application_1/features/posts/_shared/domain/ports/i_moderation_log_port.dart'
    as _i571;
import 'package:flutter_application_1/features/posts/create_post/application/create_post_cubit.dart'
    as _i382;
import 'package:flutter_application_1/features/posts/create_post/data/create_post_adapter.dart'
    as _i725;
import 'package:flutter_application_1/features/posts/create_post/domain/ports/create_post_port.dart'
    as _i219;
import 'package:flutter_application_1/features/posts/create_post/domain/usecases/create_post_usecase.dart'
    as _i470;
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_cubit.dart'
    as _i745;
import 'package:flutter_application_1/features/posts/delete_post/data/delete_post_adapter.dart'
    as _i975;
import 'package:flutter_application_1/features/posts/delete_post/domain/ports/delete_post_port.dart'
    as _i426;
import 'package:flutter_application_1/features/posts/delete_post/domain/usecases/delete_post_usecase.dart'
    as _i357;
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart'
    as _i469;
import 'package:flutter_application_1/features/posts/edit_post/data/edit_post_adapter.dart'
    as _i407;
import 'package:flutter_application_1/features/posts/edit_post/data/revise_post_adapter.dart'
    as _i845;
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/edit_post_port.dart'
    as _i789;
import 'package:flutter_application_1/features/posts/edit_post/domain/ports/i_revise_post_port.dart'
    as _i528;
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart'
    as _i808;
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_cubit.dart'
    as _i457;
import 'package:flutter_application_1/features/posts/erase_db_post/data/erase_db_post_adapter.dart'
    as _i568;
import 'package:flutter_application_1/features/posts/erase_db_post/domain/ports/erase_db_post_port.dart'
    as _i191;
import 'package:flutter_application_1/features/posts/erase_db_post/domain/usecases/erase_db_post_usecase.dart'
    as _i718;
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart'
    as _i15;
import 'package:flutter_application_1/features/posts/list_posts/data/list_posts_adapter.dart'
    as _i691;
import 'package:flutter_application_1/features/posts/list_posts/domain/ports/list_posts_port.dart'
    as _i190;
import 'package:flutter_application_1/features/posts/list_posts/domain/usecases/list_posts_usecase.dart'
    as _i659;
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart'
    as _i759;
import 'package:flutter_application_1/features/posts/moderate_post/data/moderate_post_adapter.dart'
    as _i118;
import 'package:flutter_application_1/features/posts/moderate_post/domain/ports/i_moderate_post_port.dart'
    as _i374;
import 'package:flutter_application_1/features/posts/moderate_post/domain/usecases/moderate_post_usecase.dart'
    as _i1004;
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart'
    as _i977;
import 'package:flutter_application_1/features/posts/pending_posts/data/pending_posts_adapter.dart'
    as _i482;
import 'package:flutter_application_1/features/posts/pending_posts/domain/ports/pending_posts_port.dart'
    as _i970;
import 'package:flutter_application_1/features/posts/pending_posts/domain/usecases/get_pending_posts_usecase.dart'
    as _i492;
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart'
    as _i1007;
import 'package:flutter_application_1/features/posts/post_details/data/get_post_adapter.dart'
    as _i311;
import 'package:flutter_application_1/features/posts/post_details/domain/ports/post_details_port.dart'
    as _i604;
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart'
    as _i637;
import 'package:flutter_application_1/features/posts/posts_feature_module.dart'
    as _i459;
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart'
    as _i836;
import 'package:flutter_application_1/features/posts/user_posts/data/user_posts_adapter.dart'
    as _i18;
import 'package:flutter_application_1/features/posts/user_posts/domain/ports/user_posts_port.dart'
    as _i18;
import 'package:flutter_application_1/features/posts/user_posts/domain/usecases/user_posts_usecase.dart'
    as _i256;
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart'
    as _i1015;
import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_cubit.dart'
    as _i789;
import 'package:flutter_application_1/features/tiers/create_tier/data/create_tier_adapter.dart'
    as _i920;
import 'package:flutter_application_1/features/tiers/create_tier/domain/ports/create_tier_port.dart'
    as _i933;
import 'package:flutter_application_1/features/tiers/create_tier/domain/usecases/create_tier_usecase.dart'
    as _i1027;
import 'package:flutter_application_1/features/tiers/delete_tier/application/delete_tier_cubit.dart'
    as _i256;
import 'package:flutter_application_1/features/tiers/delete_tier/data/delete_tier_adapter.dart'
    as _i304;
import 'package:flutter_application_1/features/tiers/delete_tier/domain/ports/delete_tier_port.dart'
    as _i103;
import 'package:flutter_application_1/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart'
    as _i1038;
import 'package:flutter_application_1/features/tiers/edit_tier/application/edit_tier_cubit.dart'
    as _i359;
import 'package:flutter_application_1/features/tiers/edit_tier/data/edit_tier_adapter.dart'
    as _i193;
import 'package:flutter_application_1/features/tiers/edit_tier/domain/ports/edit_tier_port.dart'
    as _i1022;
import 'package:flutter_application_1/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart'
    as _i758;
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_cubit.dart'
    as _i590;
import 'package:flutter_application_1/features/tiers/list_tiers/data/list_tiers_adapter.dart'
    as _i128;
import 'package:flutter_application_1/features/tiers/list_tiers/domain/ports/list_tiers_port.dart'
    as _i359;
import 'package:flutter_application_1/features/tiers/list_tiers/domain/usecases/list_tiers_usecase.dart'
    as _i830;
import 'package:flutter_application_1/features/tiers/tier_details/application/tier_details_cubit.dart'
    as _i402;
import 'package:flutter_application_1/features/tiers/tier_details/data/get_tier_adapter.dart'
    as _i87;
import 'package:flutter_application_1/features/tiers/tier_details/domain/ports/get_tier_port.dart'
    as _i979;
import 'package:flutter_application_1/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart'
    as _i536;
import 'package:flutter_application_1/features/tiers/tiers_feature_module.dart'
    as _i790;
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart'
    as _i405;
import 'package:flutter_application_1/features/users/create_user/application/create_user_cubit.dart'
    as _i8;
import 'package:flutter_application_1/features/users/create_user/data/create_user_adapter.dart'
    as _i187;
import 'package:flutter_application_1/features/users/create_user/domain/ports/create_user_port.dart'
    as _i538;
import 'package:flutter_application_1/features/users/create_user/domain/usecases/create_user_usecase.dart'
    as _i153;
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_cubit.dart'
    as _i639;
import 'package:flutter_application_1/features/users/delete_user/data/delete_user_adapter.dart'
    as _i217;
import 'package:flutter_application_1/features/users/delete_user/domain/ports/delete_user_port.dart'
    as _i127;
import 'package:flutter_application_1/features/users/delete_user/domain/usecases/delete_user_usecase.dart'
    as _i312;
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_cubit.dart'
    as _i65;
import 'package:flutter_application_1/features/users/edit_user/data/get_user_for_edit_adapter.dart'
    as _i392;
import 'package:flutter_application_1/features/users/edit_user/data/update_user_adapter.dart'
    as _i672;
import 'package:flutter_application_1/features/users/edit_user/domain/ports/get_user_for_edit_port.dart'
    as _i563;
import 'package:flutter_application_1/features/users/edit_user/domain/ports/update_user_port.dart'
    as _i430;
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/get_user_for_edit_usecase.dart'
    as _i788;
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/update_user_usecase.dart'
    as _i762;
import 'package:flutter_application_1/features/users/erase_db_user/application/erase_db_user_cubit.dart'
    as _i793;
import 'package:flutter_application_1/features/users/erase_db_user/data/erase_db_user_adapter.dart'
    as _i1060;
import 'package:flutter_application_1/features/users/erase_db_user/domain/ports/erase_db_user_port.dart'
    as _i573;
import 'package:flutter_application_1/features/users/erase_db_user/domain/usecases/erase_db_user_usecase.dart'
    as _i78;
import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_cubit.dart'
    as _i552;
import 'package:flutter_application_1/features/users/get_user_tier/data/get_user_tier_adapter.dart'
    as _i207;
import 'package:flutter_application_1/features/users/get_user_tier/domain/ports/get_user_tier_port.dart'
    as _i720;
import 'package:flutter_application_1/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart'
    as _i920;
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart'
    as _i828;
import 'package:flutter_application_1/features/users/list_users/data/list_users_adapter.dart'
    as _i939;
import 'package:flutter_application_1/features/users/list_users/domain/ports/list_users_port.dart'
    as _i1053;
import 'package:flutter_application_1/features/users/list_users/domain/usecases/get_users_usecase.dart'
    as _i425;
import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_cubit.dart'
    as _i729;
import 'package:flutter_application_1/features/users/moderator_contract/data/moderator_management_adapter.dart'
    as _i794;
import 'package:flutter_application_1/features/users/moderator_contract/domain/ports/moderator_management_port.dart'
    as _i522;
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart'
    as _i921;
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart'
    as _i771;
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart'
    as _i147;
import 'package:flutter_application_1/features/users/update_user_tier/data/fetch_tiers_adapter.dart'
    as _i970;
import 'package:flutter_application_1/features/users/update_user_tier/data/update_user_tier_adapter.dart'
    as _i116;
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/fetch_tiers_port.dart'
    as _i909;
import 'package:flutter_application_1/features/users/update_user_tier/domain/ports/update_user_tier_port.dart'
    as _i733;
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/fetch_tiers_usecase.dart'
    as _i273;
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart'
    as _i71;
import 'package:flutter_application_1/features/users/user_details/application/user_details_cubit.dart'
    as _i1065;
import 'package:flutter_application_1/features/users/user_details/data/get_user_adapter.dart'
    as _i678;
import 'package:flutter_application_1/features/users/user_details/domain/ports/get_user_port.dart'
    as _i765;
import 'package:flutter_application_1/features/users/user_details/domain/usecases/get_user_usecase.dart'
    as _i30;
import 'package:flutter_application_1/features/users/users_feature_module.dart'
    as _i824;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final authModule = _$AuthModule();
  final appModule = _$AppModule();
  final postsFeatureModule = _$PostsFeatureModule();
  final tiersFeatureModule = _$TiersFeatureModule();
  final usersFeatureModule = _$UsersFeatureModule();
  gh.lazySingleton<_i558.FlutterSecureStorage>(() => authModule.secureStorage);
  gh.lazySingleton<_i623.TokenHolder>(() => _i623.TokenHolder());
  gh.lazySingleton<_i361.Dio>(() => appModule.dio());
  gh.lazySingleton<_i964.PostEventBus>(
    () => _i964.PostEventBus(),
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i268.TokenStoragePort>(
    () => _i761.SecureTokenStorageAdapter(gh<_i558.FlutterSecureStorage>()),
  );
  gh.lazySingleton<_i672.AppLogger>(() => _i896.ConsoleLoggerAdapter());
  gh.lazySingleton<_i53.AuthApiClient>(
    () => authModule.authApiClient(gh<_i361.Dio>()),
  );
  gh.lazySingleton<_i72.PostsApiClient>(
    () => postsFeatureModule.postsApiClient(gh<_i361.Dio>()),
  );
  gh.lazySingleton<_i1015.TiersApiClient>(
    () => tiersFeatureModule.tiersApiClient(gh<_i361.Dio>()),
  );
  gh.lazySingleton<_i405.UsersApiClient>(
    () => usersFeatureModule.usersApiClient(gh<_i361.Dio>()),
  );
  gh.lazySingleton<_i127.DeleteUserPort>(
    () => _i217.DeleteUserAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i1053.ListUsersPort>(
    () => _i939.ListUsersAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i563.GetUserForEditPort>(
    () => _i392.GetUserForEditAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i191.EraseDbPostPort>(
    () => _i568.EraseDbPostAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i604.PostDetailsPort>(
    () =>
        _i311.GetPostAdapter(gh<_i72.PostsApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i734.AuthApiPort>(
    () => _i377.AuthApiAdapter(gh<_i53.AuthApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i219.CreatePostPort>(
    () => _i725.CreatePostAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i970.PendingPostsPort>(
    () => _i482.PendingPostsAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i492.GetPendingPostsUseCase>(
    () => _i492.GetPendingPostsUseCase(gh<_i970.PendingPostsPort>()),
  );
  gh.lazySingleton<_i103.DeleteTierPort>(
    () => _i304.DeleteTierAdapter(
      gh<_i1015.TiersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i528.IRevisePostPort>(
    () => _i845.RevisePostAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i312.DeleteUserUseCase>(
    () => _i312.DeleteUserUseCase(gh<_i127.DeleteUserPort>()),
  );
  gh.lazySingleton<_i933.CreateTierPort>(
    () => _i920.CreateTierAdapter(
      gh<_i1015.TiersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i788.GetUserForEditUseCase>(
    () => _i788.GetUserForEditUseCase(gh<_i563.GetUserForEditPort>()),
  );
  gh.lazySingleton<_i979.GetTierPort>(
    () =>
        _i87.GetTierAdapter(gh<_i1015.TiersApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i789.EditPostPort>(
    () =>
        _i407.EditPostAdapter(gh<_i72.PostsApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i374.IModeratePostPort>(
    () => _i118.ModeratePostAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i18.UserPostsPort>(
    () =>
        _i18.UserPostsAdapter(gh<_i72.PostsApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i571.IModerationLogPort>(
    () => _i139.ModerationLogAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i425.GetUsersUseCase>(
    () => _i425.GetUsersUseCase(gh<_i1053.ListUsersPort>()),
  );
  gh.lazySingleton<_i359.ListTiersPort>(
    () => _i128.ListTiersAdapter(
      gh<_i1015.TiersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i1038.DeleteTierUseCase>(
    () => _i1038.DeleteTierUseCase(gh<_i103.DeleteTierPort>()),
  );
  gh.lazySingleton<_i657.AuthCubit>(
    () => _i657.AuthCubit(
      gh<_i734.AuthApiPort>(),
      gh<_i268.TokenStoragePort>(),
      gh<_i623.TokenHolder>(),
    ),
  );
  gh.lazySingleton<_i1022.EditTierPort>(
    () => _i193.EditTierAdapter(
      gh<_i1015.TiersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i426.DeletePostPort>(
    () => _i975.DeletePostAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i637.GetPostUseCase>(
    () => _i637.GetPostUseCase(gh<_i604.PostDetailsPort>()),
  );
  gh.lazySingleton<_i190.ListPostsPort>(
    () => _i691.ListPostsAdapter(
      gh<_i72.PostsApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i256.UserPostsUseCase>(
    () => _i256.UserPostsUseCase(gh<_i18.UserPostsPort>()),
  );
  gh.lazySingleton<_i765.GetUserPort>(
    () =>
        _i678.GetUserAdapter(gh<_i405.UsersApiClient>(), gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i733.UpdateUserTierPort>(
    () => _i116.UpdateUserTierAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i71.UpdateUserTierUseCase>(
    () => _i71.UpdateUserTierUseCase(gh<_i733.UpdateUserTierPort>()),
  );
  gh.factory<_i718.EraseDbPostUseCase>(
    () => _i718.EraseDbPostUseCase(gh<_i191.EraseDbPostPort>()),
  );
  gh.factory<_i977.PendingPostsCubit>(
    () => _i977.PendingPostsCubit(
      gh<_i492.GetPendingPostsUseCase>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.lazySingleton<_i910.LocaleStoragePort>(
    () => _i270.HiveLocaleStorageAdapter(gh<_i672.AppLogger>()),
  );
  gh.lazySingleton<_i430.UpdateUserPort>(
    () => _i672.UpdateUserAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i909.FetchTiersPort>(
    () => _i970.FetchTiersAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i522.ModeratorManagementPort>(
    () => _i794.ModeratorManagementAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i470.CreatePostUseCase>(
    () => _i470.CreatePostUseCase(
      gh<_i219.CreatePostPort>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i457.EraseDbPostCubit>(
    () => _i457.EraseDbPostCubit(
      gh<_i718.EraseDbPostUseCase>(),
      gh<_i657.AuthCubit>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.lazySingleton<_i538.CreateUserPort>(
    () => _i187.CreateUserAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.lazySingleton<_i553.AuthGuard>(
    () => _i553.AuthGuard(gh<_i657.AuthCubit>()),
  );
  gh.lazySingleton<_i1041.PermissionCubit>(
    () => _i1041.PermissionCubit(gh<_i657.AuthCubit>()),
  );
  gh.lazySingleton<_i720.GetUserTierPort>(
    () => _i207.GetUserTierAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i1004.ModeratePostUseCase>(
    () => _i1004.ModeratePostUseCase(gh<_i374.IModeratePostPort>()),
  );
  gh.lazySingleton<_i573.EraseDbUserPort>(
    () => _i1060.EraseDbUserAdapter(
      gh<_i405.UsersApiClient>(),
      gh<_i672.AppLogger>(),
    ),
  );
  gh.factory<_i256.DeleteTierCubit>(
    () => _i256.DeleteTierCubit(
      gh<_i1038.DeleteTierUseCase>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i758.EditTierUseCase>(
    () => _i758.EditTierUseCase(gh<_i1022.EditTierPort>()),
  );
  gh.factory<_i292.ModerationLogCubit>(
    () => _i292.ModerationLogCubit(gh<_i571.IModerationLogPort>()),
  );
  gh.factory<_i153.CreateUserUseCase>(
    () => _i153.CreateUserUseCase(gh<_i538.CreateUserPort>()),
  );
  gh.factory<_i828.UsersListCubit>(
    () => _i828.UsersListCubit(gh<_i425.GetUsersUseCase>()),
  );
  gh.factory<_i762.UpdateUserUseCase>(
    () => _i762.UpdateUserUseCase(gh<_i430.UpdateUserPort>()),
  );
  gh.factory<_i65.EditUserCubit>(
    () => _i65.EditUserCubit(
      gh<_i788.GetUserForEditUseCase>(),
      gh<_i762.UpdateUserUseCase>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i1007.PostDetailsCubit>(
    () => _i1007.PostDetailsCubit(gh<_i637.GetPostUseCase>()),
  );
  gh.lazySingleton<_i1073.LocaleCubit>(
    () => _i1073.LocaleCubit(gh<_i910.LocaleStoragePort>()),
  );
  gh.lazySingleton<_i830.ListTiersUseCase>(
    () => _i830.ListTiersUseCase(gh<_i359.ListTiersPort>()),
  );
  gh.factory<_i273.FetchTiersUseCase>(
    () => _i273.FetchTiersUseCase(gh<_i909.FetchTiersPort>()),
  );
  gh.factory<_i536.GetTierUsecase>(
    () => _i536.GetTierUsecase(
      gh<_i979.GetTierPort>(),
      gh<_i1041.PermissionCubit>(),
    ),
  );
  gh.factory<_i8.CreateUserCubit>(
    () => _i8.CreateUserCubit(gh<_i153.CreateUserUseCase>()),
  );
  gh.factory<_i659.ListPostsUseCase>(
    () => _i659.ListPostsUseCase(gh<_i190.ListPostsPort>()),
  );
  gh.factory<_i15.ListPostsCubit>(
    () => _i15.ListPostsCubit(
      gh<_i659.ListPostsUseCase>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.factory<_i808.EditPostUseCase>(
    () => _i808.EditPostUseCase(
      gh<_i789.EditPostPort>(),
      gh<_i528.IRevisePostPort>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i357.DeletePostUseCase>(
    () => _i357.DeletePostUseCase(
      gh<_i426.DeletePostPort>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i745.DeletePostCubit>(
    () => _i745.DeletePostCubit(
      gh<_i357.DeletePostUseCase>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.factory<_i639.DeleteUserCubit>(
    () => _i639.DeleteUserCubit(
      gh<_i312.DeleteUserUseCase>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i921.AssignModeratorUseCase>(
    () => _i921.AssignModeratorUseCase(gh<_i522.ModeratorManagementPort>()),
  );
  gh.factory<_i771.RevokeModeratorUseCase>(
    () => _i771.RevokeModeratorUseCase(gh<_i522.ModeratorManagementPort>()),
  );
  gh.lazySingleton<_i30.GetUserUseCase>(
    () => _i30.GetUserUseCase(gh<_i765.GetUserPort>()),
  );
  gh.factory<_i590.ListTiersCubit>(
    () => _i590.ListTiersCubit(
      gh<_i830.ListTiersUseCase>(),
      gh<_i1041.PermissionCubit>(),
    ),
  );
  gh.factory<_i836.UserPostsCubit>(
    () => _i836.UserPostsCubit(
      gh<_i256.UserPostsUseCase>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.factory<_i359.EditTierCubit>(
    () => _i359.EditTierCubit(gh<_i758.EditTierUseCase>()),
  );
  gh.factory<_i469.EditPostCubit>(
    () => _i469.EditPostCubit(gh<_i808.EditPostUseCase>()),
  );
  gh.factory<_i759.ModeratePostCubit>(
    () => _i759.ModeratePostCubit(
      gh<_i1004.ModeratePostUseCase>(),
      gh<_i964.PostEventBus>(),
    ),
  );
  gh.factory<_i382.CreatePostCubit>(
    () => _i382.CreatePostCubit(gh<_i470.CreatePostUseCase>()),
  );
  gh.factory<_i78.EraseDbUserUseCase>(
    () => _i78.EraseDbUserUseCase(gh<_i573.EraseDbUserPort>()),
  );
  gh.factory<_i1027.CreateTierUseCase>(
    () => _i1027.CreateTierUseCase(
      gh<_i933.CreateTierPort>(),
      gh<_i1041.PermissionCubit>(),
    ),
  );
  gh.factory<_i402.TierDetailsCubit>(
    () => _i402.TierDetailsCubit(gh<_i536.GetTierUsecase>()),
  );
  gh.lazySingleton<_i920.GetUserTierUseCase>(
    () => _i920.GetUserTierUseCase(gh<_i720.GetUserTierPort>()),
  );
  gh.factory<_i147.UpdateUserTierCubit>(
    () => _i147.UpdateUserTierCubit(
      gh<_i273.FetchTiersUseCase>(),
      gh<_i71.UpdateUserTierUseCase>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i1065.UserDetailsCubit>(
    () => _i1065.UserDetailsCubit(gh<_i30.GetUserUseCase>()),
  );
  gh.factory<_i793.EraseDbUserCubit>(
    () => _i793.EraseDbUserCubit(
      gh<_i78.EraseDbUserUseCase>(),
      gh<_i657.AuthCubit>(),
    ),
  );
  gh.factory<_i729.AssignModeratorCubit>(
    () => _i729.AssignModeratorCubit(
      gh<_i921.AssignModeratorUseCase>(),
      gh<_i771.RevokeModeratorUseCase>(),
    ),
  );
  gh.factory<_i552.GetUserTierCubit>(
    () => _i552.GetUserTierCubit(gh<_i920.GetUserTierUseCase>()),
  );
  gh.factory<_i789.CreateTierCubit>(
    () => _i789.CreateTierCubit(gh<_i1027.CreateTierUseCase>()),
  );
  return getIt;
}

class _$AuthModule extends _i136.AuthModule {}

class _$AppModule extends _i690.AppModule {}

class _$PostsFeatureModule extends _i459.PostsFeatureModule {}

class _$TiersFeatureModule extends _i790.TiersFeatureModule {}

class _$UsersFeatureModule extends _i824.UsersFeatureModule {}
