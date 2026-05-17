import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_tiers_state.freezed.dart';

enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class ListTiersState with _$ListTiersState {
  const factory ListTiersState.initial() = ListTiersInitial;
  const factory ListTiersState.loading() = ListTiersLoading;
  const factory ListTiersState.loaded({
    required List<Tier> tiers,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = ListTiersLoaded;
  const factory ListTiersState.error(Failure failure) = ListTiersError;
}
