import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/ports/delete_tier_port.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/domain/usecases/delete_tier_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteTierPort extends Mock implements DeleteTierPort {}

void main() {
  group('DeleteTierUseCase', () {
    late _MockDeleteTierPort port;

    setUp(() {
      port = _MockDeleteTierPort();
    });

    test('returns Left(permissionDenied) when isSuperuser is false', () async {
      final useCase = DeleteTierUseCase(port);
      final result = await useCase(id: 42, isSuperuser: false);
      expect(result, const Left<Failure, Unit>(Failure.permissionDenied()));
      verifyNever(() => port(any()));
    });

    test(
      'returns Right(unit) when isSuperuser is true and port succeeds',
      () async {
        when(() => port(42)).thenAnswer((_) async => const Right(unit));
        final useCase = DeleteTierUseCase(port);
        final result = await useCase(id: 42, isSuperuser: true);
        expect(result, const Right<Failure, Unit>(unit));
        verify(() => port(42)).called(1);
      },
    );
  });
}
