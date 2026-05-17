import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_state.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_cubit.dart';
import 'package:flutter_application_1/features/users/update_user_tier/application/update_user_tier_state.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/fetch_tiers_usecase.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/usecases/update_user_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFetchTiersUseCase extends Mock implements FetchTiersUseCase {}

class _MockUpdateUserTierUseCase extends Mock
    implements UpdateUserTierUseCase {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

const _tier1 = TierOption(id: 1, name: 'Free');
const _tier2 = TierOption(id: 2, name: 'Pro');
const _tiers = <TierOption>[_tier1, _tier2];

void main() {
  group('UpdateUserTierCubit', () {
    late _MockFetchTiersUseCase fetchTiers;
    late _MockUpdateUserTierUseCase updateTier;
    late _MockAuthCubit authCubit;

    setUp(() {
      fetchTiers = _MockFetchTiersUseCase();
      updateTier = _MockUpdateUserTierUseCase();
      authCubit = _MockAuthCubit();
    });

    UpdateUserTierCubit build() =>
        UpdateUserTierCubit(fetchTiers, updateTier, authCubit);

    group('loadTiers', () {
      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits [loadingTiers, tiersLoaded] on success',
        build: () {
          when(() => fetchTiers()).thenAnswer(
            (_) async => const Right(_tiers),
          );
          return build();
        },
        act: (c) => c.loadTiers(),
        expect: () => [
          const UpdateUserTierState.loadingTiers(),
          const UpdateUserTierState.tiersLoaded(tiers: _tiers),
        ],
      );

      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits [loadingTiers, error(ServerFailure)] on failure',
        build: () {
          when(() => fetchTiers()).thenAnswer(
            (_) async => const Left(Failure.server()),
          );
          return build();
        },
        act: (c) => c.loadTiers(),
        expect: () => [
          const UpdateUserTierState.loadingTiers(),
          const UpdateUserTierState.error(Failure.server()),
        ],
      );
    });

    group('selectTier', () {
      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits tiersLoaded with selectedTierId when in tiersLoaded state',
        build: build,
        seed: () => const UpdateUserTierState.tiersLoaded(tiers: _tiers),
        act: (c) => c.selectTier(2),
        expect: () => [
          const UpdateUserTierState.tiersLoaded(
            tiers: _tiers,
            selectedTierId: 2,
          ),
        ],
      );

      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'does nothing when not in tiersLoaded state',
        build: build,
        seed: () => const UpdateUserTierState.initial(),
        act: (c) => c.selectTier(2),
        expect: () => <UpdateUserTierState>[],
      );
    });

    group('submit', () {
      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits [submitting, success] when isSuperuser is true',
        build: () {
          when(() => authCubit.currentUser).thenReturn(
            const CurrentUser(
              username: 'admin',
              email: '',
              name: '',
              isSuperuser: true,
              isModerator: false,
            ),
          );
          when(
            () => updateTier(
              username: any(named: 'username'),
              tierId: any(named: 'tierId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Right(unit));
          return build();
        },
        seed: () => const UpdateUserTierState.tiersLoaded(
          tiers: _tiers,
          selectedTierId: 2,
        ),
        act: (c) => c.submit('alice'),
        expect: () => [
          const UpdateUserTierState.submitting(
            tiers: _tiers,
            selectedTierId: 2,
          ),
          const UpdateUserTierState.success(),
        ],
      );

      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits [submitting, error(PermissionDenied)] when isSuperuser is false',
        build: () {
          when(() => authCubit.currentUser).thenReturn(
            const CurrentUser(
              username: 'user',
              email: '',
              name: '',
              isSuperuser: false,
              isModerator: false,
            ),
          );
          when(
            () => updateTier(
              username: any(named: 'username'),
              tierId: any(named: 'tierId'),
              isSuperuser: any(named: 'isSuperuser'),
            ),
          ).thenAnswer((_) async => const Left(Failure.permissionDenied()));
          return build();
        },
        seed: () => const UpdateUserTierState.tiersLoaded(
          tiers: _tiers,
          selectedTierId: 2,
        ),
        act: (c) => c.submit('alice'),
        expect: () => [
          const UpdateUserTierState.submitting(
            tiers: _tiers,
            selectedTierId: 2,
          ),
          const UpdateUserTierState.error(Failure.permissionDenied()),
        ],
      );

      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'does nothing and does not call updateTier when selectedTierId is null',
        build: build,
        seed: () => const UpdateUserTierState.tiersLoaded(tiers: _tiers),
        act: (c) => c.submit('alice'),
        expect: () => <UpdateUserTierState>[],
        verify: (_) => verifyNever(
          () => updateTier(
            username: any(named: 'username'),
            tierId: any(named: 'tierId'),
            isSuperuser: any(named: 'isSuperuser'),
          ),
        ),
      );
    });

    group('reset', () {
      blocTest<UpdateUserTierCubit, UpdateUserTierState>(
        'emits [initial]',
        build: build,
        seed: () => const UpdateUserTierState.tiersLoaded(tiers: _tiers),
        act: (c) => c.reset(),
        expect: () => [const UpdateUserTierState.initial()],
      );
    });
  });
}
