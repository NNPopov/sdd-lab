import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_details_state.freezed.dart';

@freezed
sealed class PostDetailsState with _$PostDetailsState {
  const factory PostDetailsState.initial() = PostDetailsInitial;
  const factory PostDetailsState.loading() = PostDetailsLoading;
  const factory PostDetailsState.loaded({required Post post}) =
      PostDetailsLoaded;
  const factory PostDetailsState.error({required Failure failure}) =
      PostDetailsError;
}
