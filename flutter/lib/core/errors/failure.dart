import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.server({
    int? statusCode,
    String? message,
  }) = ServerFailure;
  const factory Failure.cache({String? message}) = CacheFailure;
  const factory Failure.permissionDenied() = PermissionDenied;
  const factory Failure.fieldValidation({
    required Map<String, String> fields,
  }) = FieldValidationFailure;
  const factory Failure.messageValidation({required String message}) =
      MessageValidationFailure;
  const factory Failure.conflict({required String message}) = ConflictFailure;
  const factory Failure.notFound({String? message}) = NotFoundFailure;
  const factory Failure.unknown({Object? error}) = UnknownFailure;
  const factory Failure.invalidCredentials({required String message}) =
      InvalidCredentialsFailure;
  const factory Failure.forbidden({required String message}) = ForbiddenFailure;
  const factory Failure.unauthorized({required String message}) =
      UnauthorizedFailure;
}
