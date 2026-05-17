import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_log_entry.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderation_log_state.freezed.dart';

@freezed
sealed class ModerationLogState with _$ModerationLogState {
  const factory ModerationLogState.initial() = ModerationLogInitial;
  const factory ModerationLogState.loading() = ModerationLogLoading;
  const factory ModerationLogState.loaded(List<ModerationLogEntry> entries) =
      ModerationLogLoaded;
  const factory ModerationLogState.error(Failure failure) = ModerationLogError;
}
