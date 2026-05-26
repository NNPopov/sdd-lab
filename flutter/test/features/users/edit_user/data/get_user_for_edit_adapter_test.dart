import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/edit_user/data/get_user_for_edit_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('GetUserForEditAdapter.call', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late GetUserForEditAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = GetUserForEditAdapter(apiClient, mockLogger);
    });

    test('returns UnknownFailure on unexpected exception', () async {
      when(() => apiClient.getUser(any())).thenThrow(TypeError());

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
