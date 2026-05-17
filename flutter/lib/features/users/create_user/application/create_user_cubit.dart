import 'package:flutter_application_1/features/users/create_user/application/create_user_state.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_application_1/features/users/create_user/domain/usecases/create_user_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateUserCubit extends Cubit<CreateUserState> {
  CreateUserCubit(this._createUser) : super(const CreateUserState.initial());

  final CreateUserUseCase _createUser;

  Future<void> submit(NewUserData data) async {
    emit(const CreateUserState.submitting());
    final result = await _createUser(data);
    result.fold(
      (f) => emit(CreateUserState.failure(f)),
      (u) => emit(CreateUserState.success(u)),
    );
  }
}
