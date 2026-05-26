import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/delete_post/application/delete_post_state.dart';
import 'package:flutter_application_1/features/posts/delete_post/domain/usecases/delete_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeletePostCubit extends Cubit<DeletePostState> {
  DeletePostCubit(this._deletePost, this._eventBus)
    : super(const DeletePostState.initial());

  final DeletePostUseCase _deletePost;
  final PostEventBus _eventBus;

  void requestConfirmation() => emit(const DeletePostState.confirming());

  Future<void> confirmAndDelete(int userId, int id) async {
    emit(const DeletePostState.deleting());
    final result = await _deletePost(userId, id);
    result.fold(
      (f) => emit(DeletePostState.failure(f)),
      (_) {
        _eventBus.publish(PostDeleted(id));
        emit(const DeletePostState.success());
      },
    );
  }

  void cancel() {
    if (state is DeletePostConfirming) {
      emit(const DeletePostState.initial());
    }
  }
}
