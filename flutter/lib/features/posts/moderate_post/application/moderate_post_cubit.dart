import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/domain/usecases/moderate_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class ModeratePostCubit extends Cubit<ModeratePostState> {
  ModeratePostCubit(this._useCase, this._eventBus)
    : super(const ModeratePostState.initial());

  final ModeratePostUseCase _useCase;
  final PostEventBus _eventBus;

  Future<void> moderate({
    required String postUuid,
    required String action,
    String? message,
  }) async {
    emit(const ModeratePostState.loading());
    final result = await _useCase(
      postUuid: postUuid,
      action: action,
      message: message,
    );
    result.fold(
      (f) => emit(ModeratePostState.error(f)),
      (status) {
        _eventBus.publish(PostModeratedEvent(postUuid));
        emit(ModeratePostState.success(status));
      },
    );
  }
}
