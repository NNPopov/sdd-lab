import 'package:flutter_application_1/features/users/moderator_contract/application/assign_moderator_state.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/assign_moderator_usecase.dart';
import 'package:flutter_application_1/features/users/moderator_contract/domain/usecases/revoke_moderator_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AssignModeratorCubit extends Cubit<AssignModeratorState> {
  AssignModeratorCubit(this._assign, this._revoke)
    : super(const AssignModeratorState.initial());

  final AssignModeratorUseCase _assign;
  final RevokeModeratorUseCase _revoke;

  Future<void> assign(String username) async {
    emit(const AssignModeratorState.loading());
    final result = await _assign(username);
    result.fold(
      (f) => emit(AssignModeratorState.error(f)),
      (_) => emit(const AssignModeratorState.success(isModerator: true)),
    );
  }

  Future<void> revoke(String username) async {
    emit(const AssignModeratorState.loading());
    final result = await _revoke(username);
    result.fold(
      (f) => emit(AssignModeratorState.error(f)),
      (_) => emit(const AssignModeratorState.success(isModerator: false)),
    );
  }
}
