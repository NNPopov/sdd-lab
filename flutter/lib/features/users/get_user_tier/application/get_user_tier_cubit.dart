import 'package:flutter_application_1/features/users/get_user_tier/application/get_user_tier_state.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/usecases/get_user_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetUserTierCubit extends Cubit<GetUserTierState> {
  GetUserTierCubit(this._getUserTier) : super(const GetUserTierState.initial());

  final GetUserTierUseCase _getUserTier;

  Future<void> load(int userId) async {
    emit(const GetUserTierState.loading());
    final result = await _getUserTier(userId);
    result.fold(
      (f) => emit(GetUserTierState.error(f)),
      (tier) => emit(GetUserTierState.loaded(tier)),
    );
  }
}
