import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'users_list_state.freezed.dart';

enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class UsersListState with _$UsersListState {
  const factory UsersListState.initial() = UsersListInitial;
  const factory UsersListState.loading() = UsersListLoading;
  const factory UsersListState.loaded({
    required List<User> users,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = UsersListLoaded;
  const factory UsersListState.error(Failure failure) = UsersListError;
}
