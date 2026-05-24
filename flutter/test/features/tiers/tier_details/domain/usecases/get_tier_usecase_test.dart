import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/rbac/permission.dart';
import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/ports/get_tier_port.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/usecases/get_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetTierPort extends Mock implements GetTierPort {}

class _MockPermissionCubit extends Mock implements PermissionCubit {}

void main() {
  group('GetTierUsecase', () {
    late _MockGetTierPort port;
    late _MockPermissionCubit permissions;
    late GetTierUsecase usecase;

    final tier = TierDetail(
      id: 1,
      name: 'Free',
      createdAt: DateTime(2026, 4, 25),
    );

    setUp(() {
      port = _MockGetTierPort();
      permissions = _MockPermissionCubit();
      usecase = GetTierUsecase(port, permissions);
    });

    test(
      'returns Left(PermissionDenied) without calling port '
      'when manageTiers is absent',
      () async {
        when(
          () => permissions.has(Permission.manageTiers),
        ).thenReturn(false);

        final result = await usecase(1);

        result.fold(
          (f) => expect(f, isA<PermissionDenied>()),
          (_) => fail('Expected Left'),
        );
        verifyNever(() => port(any()));
      },
    );

    test(
      'returns Right(tier) when manageTiers is present and port succeeds',
      () async {
        when(
          () => permissions.has(Permission.manageTiers),
        ).thenReturn(true);
        when(() => port(1)).thenAnswer((_) async => Right(tier));

        final result = await usecase(1);

        result.fold(
          (f) => fail('Expected Right, got Left($f)'),
          (t) {
            expect(t.id, 1);
            expect(t.name, 'Free');
          },
        );
        verify(() => port(1)).called(1);
      },
    );

    test(
      'returns Left(failure) when manageTiers is present and port fails',
      () async {
        when(
          () => permissions.has(Permission.manageTiers),
        ).thenReturn(true);
        when(
          () => port(1),
        ).thenAnswer((_) async => const Left(Failure.notFound()));

        final result = await usecase(1);

        result.fold(
          (f) => expect(f, isA<NotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      },
    );
  });
}
