import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/ports/edit_tier_port.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/usecases/edit_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEditTierPort extends Mock implements EditTierPort {}

void main() {
  group('EditTierUseCase', () {
    late _MockEditTierPort port;
    late EditTierUseCase useCase;

    const data = EditTierData(tierId: 1, name: 'basic');

    setUpAll(() {
      registerFallbackValue(data);
    });

    setUp(() {
      port = _MockEditTierPort();
      useCase = EditTierUseCase(port);
    });

    test('returns Left(PermissionDenied) and does not call port '
        'when not superuser', () async {
      final result = await useCase(data: data, isSuperuser: false);

      result.fold(
        (l) => expect(l, isA<PermissionDenied>()),
        (r) => fail('Expected Left, got Right($r)'),
      );
      verifyNever(() => port(any()));
    });

    test('delegates to port and returns Right(unit) when superuser', () async {
      when(() => port(any())).thenAnswer((_) async => const Right(unit));

      final result = await useCase(data: data, isSuperuser: true);

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) => expect(r, unit),
      );
      verify(() => port(any())).called(1);
    });

    test('propagates Left(failure) from port when superuser', () async {
      const failure = Failure.notFound();
      when(() => port(any())).thenAnswer((_) async => const Left(failure));

      final result = await useCase(data: data, isSuperuser: true);

      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (r) => fail('Expected Left, got Right($r)'),
      );
    });
  });
}
