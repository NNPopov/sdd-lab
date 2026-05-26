import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/features/users/delete_user/application/delete_user_state.dart';
import 'package:flutter_application_1/features/users/delete_user/domain/usecases/delete_user_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class DeleteUserCubit extends Cubit<DeleteUserState> {
  DeleteUserCubit(this._deleteUser, this._authCubit)
    : super(const DeleteUserState.initial());

  final DeleteUserUseCase _deleteUser;
  final AuthCubit _authCubit;

  void requestConfirmation() {
    emit(const DeleteUserState.confirming());
  }

  Future<void> confirmAndDelete(int userId) async {
    emit(const DeleteUserState.deleting());
    final result = await _deleteUser(
      userId: userId,
      currentUserId: _authCubit.currentUser?.id ?? -1,
    );
    await result.fold(
      (f) async => emit(DeleteUserState.failure(f)),
      (_) async {
        // Token is now blacklisted by the server. Perform local logout without
        // the "session expired" notification — caller shows its own snackbar.
        await _authCubit.forceLogout(notifyUser: false);
        emit(const DeleteUserState.success());
      },
    );
  }

  void cancel() {
    if (state is DeleteUserConfirming) {
      emit(const DeleteUserState.initial());
    }
  }
}
