import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditPostCubit extends Cubit<EditPostState> {
  EditPostCubit(this._useCase) : super(const EditPostState.initial());

  final EditPostUseCase _useCase;

  Future<void> submit(UpdatedPostData data) async {
    emit(const EditPostState.loading());
    final result = await _useCase(data);
    result.fold(
      (failure) => emit(EditPostState.error(failure)),
      (_) => emit(const EditPostState.success()),
    );
  }
}
