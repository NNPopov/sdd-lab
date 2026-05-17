import 'package:flutter_application_1/features/posts/create_post/application/create_post_state.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/usecases/create_post_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreatePostCubit extends Cubit<CreatePostState> {
  CreatePostCubit(this._useCase) : super(const CreatePostState.initial());

  final CreatePostUseCase _useCase;

  Future<void> submit(NewPostData data) async {
    emit(const CreatePostState.loading());
    final result = await _useCase(data);
    result.fold(
      (failure) => emit(CreatePostState.error(failure)),
      (_) => emit(const CreatePostState.success()),
    );
  }
}
