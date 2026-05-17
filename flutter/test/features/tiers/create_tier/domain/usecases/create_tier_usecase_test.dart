import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/ports/create_tier_port.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/usecases/create_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateTierPort extends Mock implements CreateTierPort {}

class _MockPermissionCubit extends Mock implements PermissionCubit {}

void main() {
  group('CreateTierUseCase', () {
    late _MockCreateTierPort port;
    late _MockPermissionCubit permissions;
    late CreateTierUseCase useCase;

    const data = NewTierData(name: 'free');
    const tier = Tier(id: 1, name: 'free');

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      port = _MockCreateTierPort();
      permissions = _MockPermissionCubit();
      useCase = CreateTierUseCase(port, permissions);
    });

    test(
      'delegates to port and returns Right(tier) when permission granted',
      () async {
        when(() => permissions.has(Permission.manageTiers)).thenReturn(true);
        when(() => port(any())).thenAnswer((_) async => const Right(tier));

        final result = await useCase(data);

        result.fold(
          (l) => fail('Expected Right, got Left($l)'),
          (r) {
            expect(r.id, 1);
            expect(r.name, 'free');
          },
        );
        verify(() => port(any())).called(1);
      },
    );

    test(
      'propagates Left(failure) from port when permission granted',
      () async {
        const failure = Failure.server(statusCode: 500);
        when(() => permissions.has(Permission.manageTiers)).thenReturn(true);
        when(() => port(any())).thenAnswer((_) async => const Left(failure));

        final result = await useCase(data);

        result.fold(
          (l) => expect(l, isA<ServerFailure>()),
          (r) => fail('Expected Left, got Right($r)'),
        );
      },
    );

    test('returns Left(PermissionDenied) and does not call port '
        'when no permission', () async {
      when(() => permissions.has(Permission.manageTiers)).thenReturn(false);

      final result = await useCase(data);

      result.fold(
        (l) => expect(l, isA<PermissionDenied>()),
        (r) => fail('Expected Left, got Right($r)'),
      );
      verifyNever(() => port(any()));
    });
  });
}
