import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/application/erase_db_post_state.dart';
import 'package:flutter_application_1/features/posts/erase_db_post/domain/usecases/erase_db_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EraseDbPostCubit extends Cubit<EraseDbPostState> {
  EraseDbPostCubit(this._eraseDbPost, this._authCubit, this._eventBus)
    : super(const EraseDbPostState.initial());

  final EraseDbPostUseCase _eraseDbPost;
  final AuthCubit _authCubit;
  final PostEventBus _eventBus;

  void requestConfirmation() => emit(const EraseDbPostState.confirming());

  void cancel() {
    if (state is EraseDbPostConfirming) {
      emit(const EraseDbPostState.initial());
    }
  }

  Future<void> confirmAndErase(String username, int id) async {
    emit(const EraseDbPostState.deleting());
    final result = await _eraseDbPost(
      username: username,
      id: id,
      isSuperuser: _authCubit.currentUser?.isSuperuser ?? false,
    );
    result.fold(
      (f) => emit(EraseDbPostState.failure(f)),
      (_) {
        _eventBus.publish(PostDeleted(id));
        emit(const EraseDbPostState.success());
      },
    );
  }
}
