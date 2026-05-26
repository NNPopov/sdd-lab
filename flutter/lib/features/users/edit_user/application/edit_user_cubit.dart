import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/edit_user/application/edit_user_state.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/get_user_for_edit_usecase.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/usecases/update_user_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class EditUserCubit extends Cubit<EditUserState> {
  EditUserCubit(this._getUser, this._updateUser, this._authCubit)
    : super(const EditUserState.initial());

  final GetUserForEditUseCase _getUser;
  final UpdateUserUseCase _updateUser;
  final AuthCubit _authCubit;

  Future<void> loadInitial(int userId) async {
    emit(const EditUserState.loadingInitialData());
    if (!_authCubit.isMe(userId)) {
      emit(
        const EditUserState.loadError(
          Failure.forbidden(message: 'You can only edit your own profile'),
        ),
      );
      return;
    }
    final result = await _getUser(userId);
    result.fold(
      (f) => emit(EditUserState.loadError(f)),
      (u) => emit(EditUserState.loaded(u)),
    );
  }

  Future<void> submit(UserUpdate update) async {
    final original = switch (state) {
      EditUserLoaded(:final original) => original,
      EditUserSubmitError(:final original) => original,
      _ => null,
    };
    if (original == null) return;
    emit(EditUserState.submitting(original));
    final result = await _updateUser(original: original, update: update);
    result.fold(
      (f) => emit(EditUserState.submitError(original, f)),
      (updated) => emit(EditUserState.success(updated)),
    );
  }
}
