import 'package:flutter_application_1/features/tiers/create_tier/application/create_tier_state.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/usecases/create_tier_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class CreateTierCubit extends Cubit<CreateTierState> {
  CreateTierCubit(this._useCase) : super(const CreateTierState.initial());

  final CreateTierUseCase _useCase;

  Future<void> submit(NewTierData data) async {
    emit(const CreateTierState.submitting());
    final result = await _useCase(data);
    result.fold(
      (failure) => emit(CreateTierState.failure(failure)),
      (tier) => emit(CreateTierState.success(tier)),
    );
  }
}
